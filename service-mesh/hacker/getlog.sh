kubectl logs $(kubectl get pods -n hacker -o name -l app=hacker --field-selector=status.phase=Running) -n hacker -c hacker -f
