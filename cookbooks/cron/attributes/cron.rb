# Add one hash per cron job required
# Set the utility instance name to install each cron job on via instance_name

default[:custom_crons] = [
  {
    name: "download_latest",
    time: "45 5 * * *",
    command: "/home/deploy/bin/download_latest.sh",
    instance_name: "database"
  }
]
