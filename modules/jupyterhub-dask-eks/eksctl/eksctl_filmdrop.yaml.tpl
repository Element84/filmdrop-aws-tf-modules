apiVersion: eksctl.io/v1alpha5
kind: ClusterConfig

metadata:
  name: ${filmdrop_analytics_cluster_name}
  version: "${filmdrop_kubernetes_version}"
  region: ${filmdrop_region}

vpc:
  subnets:
    private:
    %{ for k, v in jsondecode(filmdrop_private_subnet_map) }
      ${k}: { id: ${v} }
    %{ endfor }
    public:
    %{ for k, v in jsondecode(filmdrop_public_subnet_map) }
      ${k}: { id: ${v} }
    %{ endfor }

iam:
  withOIDC: true
  serviceAccounts:
  - metadata:
      name: cluster-autoscaler
      namespace: kube-system
      labels: {aws-usage: "cluster-ops"}
    wellKnownPolicies:
      autoScaler: true
    roleName: ${filmdrop_analytics_cluster_name}-eksctl-cluster-autoscaler-role
    roleOnly: true
  - metadata:
      name: ebs-csi-controller-sa
      namespace: kube-system
      labels:
        aws-usage: "cluster-ops"
        app.kubernetes.io/name: aws-ebs-csi-driver
    wellKnownPolicies:
      ebsCSIController: true
    roleName: ${filmdrop_analytics_cluster_name}-ebs-csi-driver-role
    roleOnly: true

managedNodeGroups:
  - name: main
    minSize: ${jupyterhub_min_size}
    maxSize: ${jupyterhub_max_size}
    instanceTypes: ${jupyterhub_instance_types}
    availabilityZones: ${filmdrop_public_subnet_azs}
    privateNetworking: true
    volumeEncrypted: true
    iam:
      withAddonPolicies:
        autoScaler: true
        ebs: true
  - name: dask-workers
    minSize: ${daskhub_min_size}
    maxSize: ${daskhub_max_size}
    instanceTypes: ${daskhub_instance_types}
    availabilityZones: ${filmdrop_private_subnet_azs}
    privateNetworking: true
    volumeEncrypted: true
    spot: true
    taints:
    - key: lifecycle
      value: spot
      effect: NoExecute
    iam:
      withAddonPolicies:
        autoScaler: true
        ebs: true

secretsEncryption:
  keyARN: "${filmdrop_kms_key_arn}"
