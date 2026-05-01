#!/bin/bash
# 本地快速启动脚本
# Quick start in local.

next_boot() {
    cat << EOT
========================================
  ███╗   ██╗███████╗██╗  ██╗████████╗
  ████╗  ██║██╔════╝╚██╗██╔╝╚══██╔══╝
  ██╔██╗ ██║█████╗   ╚███╔╝    ██║
  ██║╚██╗██║██╔══╝   ██╔██╗    ██║
  ██║ ╚████║███████╗██╔╝ ██╗   ██║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝   ╚═╝
========================================
Hugo NexT version $1
Documentation: https://hugo-next.eu.org
========================================
EOT
}

next_boot `cat themes/hugo-theme-next/VERSION`

bash "$(dirname "$0")/scripts/sync-content-assets.sh"

hugo server --port 1414