locals {
  service_ssh = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "SSH"
      port = var.ssh_port
    }
  )

  service_core_p2p = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Core P2P"
      port = var.dashd_port
    }
  )

  service_core_rpc = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Core RPC"
      port = var.dashd_rpc_port
    }
  )

  service_core_zmq = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Core ZMQ"
      port = var.dashd_zmq_port
    }
  )

  service_tendermint_p2p = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Tenderdash P2P"
      port = var.tendermint_p2p_port
    }
  )

    service_prometheus = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Prometheus"
      port = var.prometheus_port
    }
  )

  service_tendermint_rpc = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Tendermint RPC"
      port = var.tendermint_rpc_port
    }
  )

  service_dapi = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "DAPI"
      port = var.gateway_port
    }
  )

  service_drive = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Drive"
      port = var.drive_port
    }
  )

  service_insight = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Insight API"
      port = var.insight_port
    }
  )

  service_kibana = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Kibana"
      port = var.kibana_port
    }
  )

  service_docker = templatefile(
    "${path.module}/templates/services/service.tpl",
    {
      name = "Docker API"
      port = var.docker_port
    }
  )

  masternodes_amd = [
    for n in range(length(aws_instance.masternode_amd)) : templatefile(
      "${path.module}/templates/services/node.tpl",
      {
        name = "masternode-amd-${n + 1}"
        external_services = replace(
          chomp(
            join(
              "",
              [
                local.service_ssh,
                local.service_core_p2p,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.masternode_amd.*.public_ip, n),
        )
        internal_services = replace(
          chomp(
            join(
              "",
              [
                local.service_core_rpc,
                local.service_core_zmq,
                local.service_insight,
                local.service_docker,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.masternode_amd.*.public_ip, n),
        )
        service_logs = chomp(
          join(
            "\n",
            [
              "   - dashd",
              "   - insight",
            ],
          ),
        )
      }
    )
  ]

  masternodes_arm = [
    for n in range(length(aws_instance.masternode_arm)) : templatefile(
      "${path.module}/templates/services/node.tpl",
      {
        name = "masternode-arm-${n + 1}"
        external_services = replace(
          chomp(
            join(
              "",
              [
                local.service_ssh,
                local.service_core_p2p,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.masternode_arm.*.public_ip, n),
        )
        internal_services = replace(
          chomp(
            join(
              "",
              [
                local.service_core_rpc,
                local.service_core_zmq,
                local.service_insight,
                local.service_docker,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.masternode_arm.*.public_ip, n),
        )
        service_logs = chomp(
          join(
            "\n",
            [
              "   - dashd",
              "   - insight",
            ],
          ),
        )
      }
    )
  ]

  masternodes = concat(local.masternodes_amd, local.masternodes_arm) #Magic...

hp_masternodes_amd = [
  for n in range(length(aws_instance.hp_masternode_amd)) : templatefile(
    "${path.module}/templates/services/node.tpl",
    {
      name = "hp-masternode-amd-${n + 1}"
      external_services = replace(
        chomp(
          join(
            "",
            [
              local.service_ssh,
              local.service_core_p2p,
              local.service_dapi,
              local.service_tendermint_p2p,
            ],
          ),
        ),
        "{{ip}}",
        var.create_eip ? element(aws_eip.hpmn_amd_eip.*.public_ip, n) : element(aws_instance.hp_masternode_amd.*.public_ip, n),
      )
      internal_services = replace(
        chomp(
          join(
            "",
            [
              local.service_tendermint_rpc,
              local.service_core_rpc,
              local.service_core_zmq,
              local.service_drive,
              local.service_insight,
              local.service_docker,
            ],
          ),
        ),
        "{{ip}}",
        var.create_eip ? element(aws_eip.hpmn_amd_eip.*.public_ip, n) : element(aws_instance.hp_masternode_amd.*.public_ip, n),
      )
      service_logs = chomp(
        join(
          "\n",
          [
            "   - dashd",
            "   - dapi_api",
            "   - dapi_tx_filter_stream",
            "   - dapi_nginx",
            "   - gateway",
            "   - drive_abci",
            "   - tendermint",
            "   - insight",
          ],
        ),
      )
    }
  )
]

 hp_masternodes_arm = [
  for n in range(length(aws_instance.hp_masternode_arm)) : templatefile(
    "${path.module}/templates/services/node.tpl",
    {
      name = "hp-masternode-amd-${n + 1}"
      external_services = replace(
        chomp(
          join(
            "",
            [
              local.service_ssh,
              local.service_core_p2p,
              local.service_dapi,
              local.service_tendermint_p2p,
            ],
          ),
        ),
        "{{ip}}",
        var.create_eip ? element(aws_eip.hpmn_arm_eip.*.public_ip, n) : element(aws_instance.hp_masternode_arm.*.public_ip, n),
      )
      internal_services = replace(
        chomp(
          join(
            "",
            [
              local.service_tendermint_rpc,
              local.service_core_rpc,
              local.service_core_zmq,
              local.service_drive,
              local.service_insight,
              local.service_docker,
            ],
          ),
        ),
        "{{ip}}",
        var.create_eip ? element(aws_eip.hpmn_arm_eip.*.public_ip, n) : element(aws_instance.hp_masternode_arm.*.public_ip, n),
      )
      service_logs = chomp(
        join(
          "\n",
          [
            "   - dashd",
            "   - dapi_api",
            "   - dapi_tx_filter_stream",
            "   - dapi_nginx",
            "   - gateway",
            "   - drive_abci",
            "   - tendermint",
            "   - insight",
          ],
        ),
      )
    }
  )
]

  hp_masternodes = concat(local.hp_masternodes_amd, local.hp_masternodes_arm) #Magic...

  wallets = [
    for n in range(length(aws_instance.dashd_wallet)) : templatefile(
      "${path.module}/templates/services/node.tpl",
      {
        name = "dashd-wallet-${n + 1}"
        external_services = replace(
          chomp(join("", [local.service_ssh])),
          "{{ip}}",
          element(aws_instance.dashd_wallet.*.public_ip, n),
        )
        internal_services = replace(
          chomp(
            join(
              "",
              [
                local.service_core_p2p,
                local.service_core_rpc,
                local.service_core_zmq,
                local.service_docker,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.dashd_wallet.*.public_ip, n),
        )
        service_logs = chomp(join("\n", ["   - dashd"]))
      }
    )
  ]

  mixers = [
    for n in range(length(aws_instance.mixer)) : templatefile(
      "${path.module}/templates/services/node.tpl",
      {
        name = "mixing-${n + 1}"
        external_services = replace(
          chomp(join("", [local.service_ssh])),
          "{{ip}}",
          element(aws_instance.mixer.*.public_ip, n),
        )
        internal_services = replace(
          chomp(
            join(
              "",
              [
                local.service_core_p2p,
                local.service_core_rpc,
                local.service_core_zmq,
                local.service_docker,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.mixer.*.public_ip, n),
        )
        service_logs = chomp(join("\n", ["   - mixing"]))
      }
    )
  ]

  seeds = [
    for n in range(length(aws_instance.seed_node)) : templatefile(
      "${path.module}/templates/services/node.tpl",
      {
        name = "seed-${n + 1}"
        external_services = replace(
          chomp(
            join(
              "",
              [
                local.service_ssh,
                local.service_core_p2p,
                local.service_dapi,
                local.service_tendermint_p2p,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.seed_node.*.public_ip, n),
        )
        internal_services = replace(
          chomp(
            join(
              "",
              [
                local.service_tendermint_rpc,
                local.service_core_rpc,
                local.service_core_zmq,
                local.service_drive,
                local.service_insight,
                local.service_docker,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.seed_node.*.public_ip, n),
        )
        service_logs = chomp(join("\n", [
          "   - dashd",
          "   - dapi_api",
          "   - dapi_tx_filter_stream",
          "   - dapi_nginx",
          "   - gateway",
          "   - drive_abci",
          "   - tendermint",
          "   - insight",
        ]))
      }
    )
  ]

  miners = [
    for n in range(length(aws_instance.miner)) : templatefile(
      "${path.module}/templates/services/node.tpl",
      {
        name = "miner-${n + 1}"
        external_services = replace(
          chomp(join("", [local.service_ssh])),
          "{{ip}}",
          element(aws_instance.miner.*.public_ip, n),
        )
        internal_services = replace(
          chomp(
            join(
              "",
              [
                local.service_core_p2p,
                local.service_core_rpc,
                local.service_docker,
              ],
            ),
          ),
          "{{ip}}",
          element(aws_instance.miner.*.public_ip, n),
        )
        service_logs = chomp(join("\n", ["   - dashd"]))
      }
    )
  ]

  services = templatefile(
    "${path.module}/templates/services/services.tpl",
    {
      masternodes    = chomp(join("\n", local.masternodes.*))
      hp_masternodes = chomp(join("\n", local.hp_masternodes.*))
      wallets        = chomp(join("\n", local.wallets.*))
      mixers         = chomp(join("\n", local.mixer_hosts.*))
      seeds          = chomp(join("\n", local.seeds.*))
      miners         = chomp(join("\n", local.miners.*))
      elb_host       = chomp(join("\n", aws_elb.web.*.dns_name))
      insight_port   = var.insight_port
      kibana_port    = var.kibana_port
      logs_host      = aws_route53_record.logs[0].name
      vpn_host       = chomp(join("\n", aws_eip.vpn.*.public_ip))
      vpn_port       = var.vpn_port
    }
  )
}

output "services" {
  value = local.services
}
