################################################################################
# Karpenter
################################################################################

resource "kubectl_manifest" "karpenter_default_ec2_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2 
      role: "${module.karpenter.node_iam_role_name}" 
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${module.eks.cluster_name}" 
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${module.eks.cluster_name}" 
  YAML
  depends_on = [
    module.eks.cluster,
    module.karpenter,
  ]
}

resource "kubectl_manifest" "karpenter_default_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["arm64", "amd64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["on-demand"]
            - key: karpenter.k8s.aws/instance-category
              operator: In
              values: ["c", "m", "r"]
            - key: karpenter.k8s.aws/instance-generation
              operator: Gt
              values: ["2"]
          nodeClassRef:
            name: default
          limits:
            cpu: 1000
          disruption:
            consolidationPolicy: WhenEmpty
            consolidateAfter: 30s
  YAML

  depends_on = [
    module.eks.cluster,
    module.karpenter,
  ]
}