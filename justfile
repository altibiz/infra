set windows-shell := ["nu.exe", "-c"]
set shell := ["nu", "-c"]

root := absolute_path('')
shebang := if os() == "windows" { "nu" } else { "/usr/bin/env nu" }

format:
    cd '{{ root }}'; just --unstable --fmt
    prettier --write '{{ root }}'
    nixfmt ...(fd '.*.nix$' '{{ root }}' | lines)
    shfmt --write '{{ root }}'

lint:
    cd '{{ root }}'; just --unstable --fmt --check
    prettier --check '{{ root }}'
    nixfmt --check ...(fd '.*.nix$' '{{ root }}' | lines)
    markdownlint --ignore-path .gitignore '{{ root }}'
    glob '{{ root }}/scripts/**/*.sh' | each { |i| shellcheck $i } | str join "\n"
    cspell lint '{{ root }}' --no-progress
    if (markdown-link-check \
      --config '{{ root }}/.markdown-link-check.json' \
      ...(fd '^.*.md$' '{{ root }}' | lines) \
      | rg -q error \
      | complete \
      | get exit_code) == 0 { exit 1 }

test:
    nix flake check

test-interactive name:
    nix run ".#checks.{{ name }}.driverInteractive"

generate name:
    #!{{ shebang }}
    let lib = nix eval --json $"{{ root }}#lib.{{ name }}" | from json
    nix build $".#nixosConfigurations.\"hosts/{{ name }}-($lib.system)\".config.formats.($lib.format)"

deploy name="" credentials="ALTIBIZ_INFRA_DEPLOY_CREDENTIALS":
    #!{{ shebang }}
    if ($env.'{{ credentials }}' | path exists) {
      open $env.'{{ credentials }}'
    } else {
      $env.'{{ credentials }}' | from yaml
    } | where {
          if ('{{ name }}' | is-empty) {
            true
          } else {
            $in.name == '{{ name }}'
          }
        }
      | par-each {
          let lib = nix eval --json $"{{ root }}#lib.($in.name)" | from json
          let flake = $"{{ root }}#($in.name)-($lib.system)"
          ssh-agent bash -c $"printf '%s' '($in.sshKey)' \\
            | ssh-add - \\
            && export SSHPASS='($in.sshPass)' \\
            && export SSH_AUTH_SOCK \\
            && sshpass -e deploy \\
              --skip-checks \\
              --interactive-sudo true \\
              --hostname ($lib.ip) \\
              -- ($flake)"
        }
      | ignore

ssh name credentials="ALTIBIZ_INFRA_DEPLOY_DEV_CREDENTIALS":
    #!{{ shebang }}
    let creds = if ($env.'{{ credentials }}' | path exists) {
      open $env.'{{ credentials }}'
    } else {
      $env.'{{ credentials }}' | from yaml
    }
    let creds = $creds | where $it.name == '{{ name }}' | first
    let lib = nix eval --json $"{{ root }}#lib.{{ name }}" | from json

    ssh-agent bash -c $"printf '%s' '($creds.sshKey)' \\
      | ssh-add - \\
      && export SSHPASS='($creds.sshPass)' \\
      && export SSH_AUTH_SOCK \\
      && sshpass -e ssh altibiz@($lib.ip)"

docs where="{{ root }}/artifacts":
    rm -rf '{{ where }}'
    cd '{{ root }}/docs'; mdbook build
    mv '{{ root }}/docs/book' '{{ where }}'
