import sys, yaml
from pathlib import Path
from jinja2 import Environment, FileSystemLoader, select_autoescape
from dotenv import dotenv_values

if len(sys.argv) < 2:
    print("Usage: render.py <service>")
    sys.exit(1)

service = sys.argv[1]
base_dir = Path("/app")

# Load global + service env
env_vars = dotenv_values(base_dir / ".env")
service_env = dotenv_values(base_dir / service / ".env")
env_vars.update(service_env)

# Load structured values (like zookeeper cluster)
values_file = base_dir / service / "values.yml"
if values_file.exists():
    with open(values_file) as f:
        env_vars.update(yaml.safe_load(f))

# Setup Jinja with multiple search paths:
#  - service folder (for docker-compose.yml.j2)
#  - base_dir (for base.yml.j2 and shared templates)
env = Environment(
    loader=FileSystemLoader([str(base_dir / service), str(base_dir)]),
    autoescape=False
)

# Load the service template
template = env.get_template("docker-compose.yml.j2")

# Render
output = template.render(**env_vars)

# Write output
out_file = base_dir / service / "docker-compose.yml"
with open(out_file, "w") as f:
    f.write(output)
