jupyterhub:
  singleuser:
    image:
      name: ${jupyterhub_image_repo}
      tag: "${jupyterhub_image_version}"
    cpu:
      limit: 2
      guarantee: 1
    memory:
      limit: 4G
      guarantee: 2G
  proxy:
    secretToken: "${dask_proxy_token}"
    https:
      enabled: true
      type: offload
    service:
      annotations:
        service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "tcp"
        service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
        service.beta.kubernetes.io/aws-load-balancer-type: "elb"
        service.beta.kubernetes.io/aws-load-balancer-subnets: "${filmdrop_public_subnet_ids}"
  hub:
    config:
      Authenticator:
        admin_users:
        %{ for v in split(",",jupyterhub_admin_username_list) }
          - ${v}
        %{ endfor }
      DummyAuthenticator:
        password: ${jupyterhub_admin_password}
      JupyterHub:
        authenticator_class: dummy
    services:
      dask-gateway:
        apiToken: "${dask_gateway_token}"
        display: false

dask-gateway:
  gateway:
    backend:
      worker:
        extraPodConfig:
          nodeSelector:
            eks.amazonaws.com/capacityType: SPOT
          tolerations:
            - key: "lifecycle"
              operator: "Equal"
              value: "spot"
              effect: "NoExecute"
    extraConfig:
      optionHandler: |
        from dask_gateway_server.options import Options, Integer, Float, String
        def option_handler(options):
            if ":" not in options.image:
                raise ValueError("When specifying an image you must also provide a tag")
            return {
                "worker_cores": options.worker_cores,
                "worker_memory": int(options.worker_memory * 2 ** 30),
                "image": options.image,
            }
        c.Backend.cluster_options = Options(
            Float("worker_cores", default=0.8, min=0.8, max=4.0, label="Worker Cores"),
            Float("worker_memory", default=3.3, min=1, max=8, label="Worker Memory (GiB)"),
            String("image", default="${jupyterhub_image_repo}:${jupyterhub_image_version}", label="Image"),
            handler=option_handler,
        )
    auth:
      type: jupyterhub
      jupyterhub:
        apiToken: "${dask_gateway_token}"
