FROM concourse/git-resource:1.7.0 as resource

RUN mv /opt/resource /opt/git-resource

# patch the git-resource deepen script with our fixes, see https://github.com/concourse/git-resource/pull/316
COPY git-resource/deepen_shallow_clone_until_ref_is_found_then_check_out /opt/git-resource/deepen_shallow_clone_until_ref_is_found_then_check_out

ADD assets/ /opt/resource/
RUN chmod +x /opt/resource/*

FROM resource AS tests
ADD test/ /tests
RUN /tests/all.sh