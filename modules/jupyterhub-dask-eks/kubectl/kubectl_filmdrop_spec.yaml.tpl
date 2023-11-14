spec:
  template:
    spec:
      containers:
      - command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/${filmdrop_analytics_cluster_name}
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        image: k8s.gcr.io/autoscaling/cluster-autoscaler:${filmdrop_analytics_cluster_autoscaler_version}
        imagePullPolicy: Always
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 600Mi
          requests:
            cpu: 100m
            memory: 600Mi
        terminationMessagePath: /dev/termination-log
        terminationMessagePolicy: File
        volumeMounts:
        - mountPath: /etc/ssl/certs/ca-certificates.crt
          name: ssl-certs
          readOnly: true
      dnsPolicy: ClusterFirst
      priorityClassName: system-cluster-critical
      restartPolicy: Always
      schedulerName: default-scheduler
      securityContext:
        fsGroup: 65534
        runAsNonRoot: true
        runAsUser: 65534
      serviceAccount: cluster-autoscaler
      serviceAccountName: cluster-autoscaler
      terminationGracePeriodSeconds: 30
      volumes:
      - hostPath:
          path: /etc/ssl/certs/ca-bundle.crt
          type: ""
        name: ssl-certs
