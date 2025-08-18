#!/usr/bin/env python3

import json
import os
import subprocess
import sys

# Path to your Terraform environment directory
TF_DIR = os.environ.get("TF_DIR")

def get_tf_outputs():
    """Run `terraform output -json` and return parsed JSON."""
    result = subprocess.run(
        ["terraform", "output", "-json"],
        cwd=TF_DIR,
        capture_output=True,
        text=True,
        check=True
    )
    return json.loads(result.stdout)

def build_inventory(tf_outputs):
    """Convert terraform outputs into an Ansible inventory dict."""
    private_ip = tf_outputs.get("jump_private_ip", {}).get("value")
    public_ip = tf_outputs.get("jump_public_ip", {}).get("value")

    inventory = {
        "jump": {
            "hosts": ["jumphost"]
        },
        "_meta": {
            "hostvars": {
                "jumphost": {
                    "ansible_host": private_ip,
                    "public_ip": public_ip
                }
            }
        }
    }

    print(json.dumps(inventory, indent=2))

if __name__ == "__main__":
    if "--list" in sys.argv:
        outputs = get_tf_outputs()
        build_inventory(outputs)
    elif "--host" in sys.argv:
        # Optional: return hostvars for one host
        print(json.dumps({}))
    else:
        print("Usage: terraform --list [--host <hostname>]", file=sys.stderr)
        sys.exit(1)

