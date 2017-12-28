FROM redis

COPY redis-master.conf /redis-master/redis.conf
COPY run.sh /run.sh

CMD [ "/run.sh" ]
ENTRYPOINT [ "sh", "-c" ]
