# dnscrypt-proxy

A [dnscrypt-proxy](https://github.com/jedisct1/dnscrypt-proxy/wiki) image using [Confd](https://github.com/kelseyhightower/confd) and [ContainerPilot](https://www.joyent.com/containerpilot/docs).

## Basic Usage

Although both Confd and ContainerPilot can use Consul, this image is fully functional without a Consul instance on your network:

```
docker run --rm -p 53:53/udp -p 53:53/tcp anleonard/dnscrypt-proxy:latest
```

## Use with Consul

By default, this image does not attempt to register the dnscrypt-proxy instance as a service in Consul via ContainerPilot, and uses `env` as the Confd backend.  If you do have Consul running, and wish to use it for service registration and as Confd's backend, set the `CONSUL` and `CONFD_BACKEND`/`CONFD_NODE` environment variables, respectively:

```
docker run --rm \
    -p 53:53/udp -p 53:53/tcp \
    -e CONSUL=consul.example.com:8500 \
    -e CONFD_BACKEND=consul
    -e CONFD_NODE=consul.example.com:8500 \
    dnscrypt-proxy:latest
```

Similarly, other Confd backends can be used if desired by passing the arguments to `-backend` and `-node` via `CONFD_BACKEND` and `CONFD_NODE`; see the [Confd docs](https://github.com/kelseyhightower/confd/tree/master/docs) for more information.

## Confd configuration keys

Confd looks up the following keys to set values in dnscrypt-proxy's configuration file:

* `/dnscryptproxy/blacklistlog/file` - Sets `blacklist:log_file`, path to a file logging blocked queries; default: `/var/log/dnscrypt-proxy/blocked.log`.
* `/dnscryptproxy/ipblacklistlog/file` - Sets `ip_blacklist:log_file`, path to a file logging queries blocked based on IP addresses in the response; default: `/var/log/dnscrypt-proxy/ip-blocked.log`.
* `/dnscryptproxy/listenaddresses` - Sets `listen_addresses`, the list of local addresses and ports to listen to.  Note that this is passed as a string containing a TOML array, and not as multiple keys under a prefix.  Default: `['0.0.0.0:53']`.
* `/dnscryptproxy/nxlog/file` - Sets `nx_log:file`, path to the log file for queries of nonexistent zones; default: `/var/log/dnscrypt-proxy/nx.log`.
* `/dnscryptproxy/querylog/file` - Sets `query_log:file`, path to the query log file; default: `/var/log/dnscrypt-proxy/query.log`.
* `/dnscryptproxy/servername/*` - Multiple keys containing servers from the "public-resolvers" source, used together to set the `server_names` array.  None are defined by default, so that all servers matching `require_*` filters are used.
* `/dnscryptproxy/whitelistlog/file` - Sets `whitelist:log_file`, the file for logging whitelisted queries; default: `/var/log/dnscrypt-proxy/whitelisted.log`.

Note that if the default `env` backend to Confd is being used, the above keys are capitalized and `/` is replaced with `_`, with the leading `_` omitted when reading environment variables.  For example, `/dnscryptproxy/blacklistlog/file` would be read from the environment variable `DNSCRYPTPROXY_BLACKLISTLOG_FILE`.  Similarly, `DNSCRYPTPROXY_SERVERNAME_A` and `DNSCRYPTPROXY_SERVERNAME_B` would each be keys read under `/dnscryptproxy/servername/*`.

## Logging

This container creates a `VOLUME` at `/var/log/dnscrypt-proxy`, which holds the log files if the defaults for their locations (see above) are used.  This allows another container to share this volume, possibly for use in log aggregation or analysis.

## Blacklists and Whitelists

The blacklist, whitelist and IP blacklist are configured to be read from within `/etc/dnscrypt-proxy`, and are all empty by default.  This location is a `VOLUME` to simplify management of these files and their preservation run-to-run.
