FROM turbot/steampipe
# Setup prerequisites (as root)
USER root:0
RUN apt-get update -y \
 && apt-get install -y git
# Install the aws and steampipe plugins for Steampipe (as steampipe user).
USER steampipe:0
RUN  mkdir -p ~/.config/gcloud \
&&  steampipe plugin install gcp \
&& steampipe plugin install kubernetes
RUN  git clone https://github.com/leegin/steampipe-mod-gcp-labels.git /workspace
WORKDIR /workspace
CMD ["steampipe", "service", "start", "--foreground", "--dashboard", "--dashboard-listen=network"]
