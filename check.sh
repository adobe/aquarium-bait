#/bin/sh
# Script to simplify the style check process

root_dir=$(realpath "$(dirname "$0")")
errors=0

echo
echo '---------------------- Custom Checks ----------------------'
echo
for f in `git ls-files`; do
    # Check text files
    if file "$f" | grep -q 'text$'; then
        # Ends with newline as POSIX requires
        if [ -n "$(tail -c 1 "$f")" ]; then
            echo "Not ends with newline: $f"
            errors=$((${errors}+1))
        fi
        # Ansible step `register` variable starts with "reg_"
        if [ "$(grep 'register:' "$f" | grep -v 'register: reg_')" ]; then
            echo "Register variable not starts with 'reg_' prefix: $f"
            errors=$((${errors}+1))
        fi
    fi
done

echo
echo '---------------------- YAML Lint ----------------------'
echo
docker run --rm -v "${root_dir}:/data" cytopia/yamllint:1.22 playbooks
errors=$((${errors}+$?))

echo
echo '---------------------- Ansible Lint ----------------------'
echo
docker run --rm -v "${root_dir}:/data" cytopia/ansible-lint:latest-0.5 playbooks/*.yml
errors=$((${errors}+$?))

exit ${errors}
