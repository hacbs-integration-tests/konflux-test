FROM quay.io/konflux-ci/buildah-task:latest@sha256:4c470b5a153c4acd14bf4f8731b5e36c61d7faafe09c2bf376bb81ce84aa5709 AS buildah-task-image
FROM quay.io/konflux-ci/task-runner:3.1.1@sha256:790df1bb5ea7a9ce4c1717ff341398ff72c99faed1c2e939a3b4a15ff8f4a493 AS appstudio-utils
FROM registry.access.redhat.com/ubi9/ubi:9.8-1786416589

# Note that the version of OPA used by pr-checks must be updated manually to reflect conftest updates
# To find the OPA version associated with conftest run the following with the relevant version of conftest:
# $ conftest --version
ARG BATS_VERSION=1.8.2

ENV POLICY_PATH="/project"

# Build dependency offline to streamline build
# Import GPG keys for RPM signature verification
RUN dnf install -y jq \
    skopeo \
    tar \
    python3 \
    git \
    golang \
    python3-file-magic \
    python3-pip \
    libicu && \
    cd .. && rm -rf "bats-core-$BATS_VERSION" && \
    cd / && \
    dnf clean all

ENV PATH="${PATH}:/sbom-utility"

COPY --from=buildah-task-image /usr/bin/retry /usr/bin/

COPY --from=appstudio-utils /usr/local/bin/select-oci-auth /usr/local/bin/select-oci-auth

COPY policies $POLICY_PATH
COPY test/conftest.sh $POLICY_PATH

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY test/selftest.sh /selftest.sh
COPY test/utils.sh /utils.sh
COPY parsers/parse_to_cve_oriented_output.jq /parse_to_cve_oriented_output.jq

LABEL "dev.konflux-ci.vendor"="Konflux Integration Team"
LABEL name="konflux-test"

ENTRYPOINT ["/usr/bin/bash"]
