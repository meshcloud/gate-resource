FROM concourse/git-resource:1.7.0 as resource

RUN mv /opt/resource /opt/git-resource

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*


FROM resource AS tests
ADD test/ /tests
RUN /tests/all.sh