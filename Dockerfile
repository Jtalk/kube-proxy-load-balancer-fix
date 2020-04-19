FROM bitnami/kubectl:1.16
COPY fix.sh /bin/fix.sh
ENTRYPOINT ["fix.sh"]
CMD []