FROM concourse/git-resource as resource

RUN mv /opt/resource /opt/git-resource

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*


FROM resource AS tests
ADD test/ /tests
RUN /tests/all.sh