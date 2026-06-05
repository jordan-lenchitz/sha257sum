FROM ubuntu:22.04

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Update and install basic tools and repositories
RUN apt-get update && apt-get install -y \
    wget curl git gnupg software-properties-common apt-transport-https build-essential \
    unzip pkg-config libelf-dev libssl-dev libicu-dev \
    && rm -rf /var/lib/apt/lists/*

# Add repos for specific languages
# Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
# .NET & PowerShell
RUN wget https://packages.microsoft.com/config/ubuntu/22.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb \
    && dpkg -i packages-microsoft-prod.deb \
    && rm packages-microsoft-prod.deb

# Install everything from apt
RUN apt-get update && apt-get install -y \
    gcc g++ gfortran \
    ghc \
    gnat \
    gnucobol \
    openjdk-17-jdk \
    kotlin \
    golang \
    nodejs \
    python3 python3-pip \
    ruby \
    perl \
    swi-prolog \
    php-cli \
    lua5.4 \
    dotnet-sdk-8.0 \
    powershell \
    octave \
    ksh \
    gawk \
    vim \
    && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | xargs -r sh -s -- -y || \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Swift
RUN wget https://download.swift.org/swift-5.10-release/ubuntu2204/swift-5.10-RELEASE/swift-5.10-RELEASE-ubuntu22.04.tar.gz \
    && tar -xzf swift-5.10-RELEASE-ubuntu22.04.tar.gz \
    && mv swift-5.10-RELEASE-ubuntu22.04 /opt/swift \
    && rm swift-5.10-RELEASE-ubuntu22.04.tar.gz
ENV PATH="/opt/swift/usr/bin:${PATH}"

# Install YottaDB (MUMPS)
RUN wget https://gitlab.com/YottaDB/DB/YDB/raw/master/sr_unix/ydbinstall.sh \
    && chmod +x ydbinstall.sh \
    && ./ydbinstall.sh --utf8 default \
    && rm ydbinstall.sh
# Ensure YottaDB environment is sourced or binary is linked
RUN ln -s /usr/local/lib/yottadb/current/mumps /usr/local/bin/mumps || true

# Install TypeScript/ts-node
RUN npm install -g typescript ts-node

# Install ttyd
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 -O /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Copy sha257sum project
WORKDIR /app/sha257sum
COPY . .

# Build the Go API
RUN go build -o sha257-api api.go

# Set up environment for the terminal
RUN echo 'export PATH="/root/.cargo/bin:/opt/swift/usr/bin:${PATH}"' >> /root/.bashrc
RUN echo 'if [ -f /usr/local/etc/ydb_env_set ]; then . /usr/local/etc/ydb_env_set; fi' >> /root/.bashrc
RUN echo 'alias mumps="ydb"' >> /root/.bashrc

# Expose ports
EXPOSE 8080
EXPOSE 8081

# Run both the Go API and ttyd
# Note: In Cloud Run, we should probably run the API on $PORT. 
# For local testing, we'll run API on 8080 and ttyd on 8081.
CMD ["sh", "-c", "./sha257-api & ttyd -p 8081 -W -t 'titleFixed=Kevin Containment Shell' bash -c 'echo -e \"\\033[0;32mWelcome to the Kevin Containment Facility!\\033[0m\nType \"cd .. && cat README.md\" to see available commands or use vim to inspect the ports.\n\nExample: ./sha257sum.py \"kevin\" \"; exec bash'"]
