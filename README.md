# CFP-???: Extendable service load-balancing control-plane

**SIG: SIG-NAME**

**Begin Design Discussion:** YYYY-MM-DD

**Cilium Release:** X.XX

**Authors:** Jussi Maki <jussi.maki@isovalent.com>

## Summary

## Motivation


## Goals

_List goals that this CFP achieves._

## Non-Goals

_List aspects which are specifically out of context for this CFP._

## Proposal

### Current design

![current design](current.svg)

### Overview

The proposed design is depicted in the diagram below. The main two ideas are:
1) Flat representation: single internal "Service" model
2) Storing the "Service" in a [StateDB](https://github.com/cilium/statedb) table

![proposal](highlevel.svg)

(1) By flattening the different representations of a "Service" (with backends)
from (corev1.Service, k8s.Service, ClusterService, loadbalancer.SVC, service.svcInfo, ...)
into a single internal model we simplify the design and make it much easier to deal with
merging and overlapping services.

(2) By storing the service model in StateDB the services can be observed by any component
in the system without locks. The observing component can be implemented in a self-contained
manner without having to splice in calls into the component into existing code. The semantics
of creating and modifying services can be implemented as a wrapper around the StateDB "RWTable"
interface, enforcing the rules for dealing with merging of backends and overrides such as L7
proxy redirection.

These two key ideas allow introducing new data sources of services and backends without requiring
existing code to change and without risking the breaking of semantics when multiple data sources
conflict (e.g. ![EnsureService fix](https://github.com/cilium/cilium/pull/13274)).

A [demo application](https://github.com/cilium/cilium/pull/30036) shows how these ideas would be
implemented in practice.

## Impacts / Key Questions

_List crucial impacts and key questions. They likely require discussion and are required to understand the trade-offs of the CFP. During the lifecycle of a CFP, discussion on design aspects can be moved into this section. After reading through this section, it should be possible to understand any potentially negative or controversial impact of this CFP. It should also be possible to derive the key design questions: X vs Y._

### Impact: ... 1

_Describe crucial impacts and key questions that likely require discussion and debate._

### Key Question: Lifetime of a "Service"

TODO define the lifetime of how a service can evolve and work through the different
scenarios when multiple data sources interact/overlap with a service.

#### Overrides

Currently L7 proxy redirection and LocalRedirectPolicy are the main things that
"augment" an existing service that has come from another data source. The implementation
must be such that e.g. LocalRedirectPolicy can be applied to a service before other details
for the service arrive and that if a LocalRedirectPolicy is removed the original service is
restored.

#### Backend merging

The other interaction across data sources on a single service is the merging of backends
from other Cilium clusters via ClusterMesh. These are stored as "ClusterServices" in etcd
and are merged with existing services of the local cluster to add the backends in the other
clusters to it. The implementation must be able to deal with adding backends to a service
before the service frontend details arrive. It must also be possible to manipulate backends
based on its source (e.g. to remove all backends that came from a specific data source).

This likely implies that the information on how a backend maps to a service should be stored
in a separate "backend" table to allow services to come and go independent of the backends
associated with them. E.g. backends are first added to a backend table after which the
services that the new backends refer to are updated to refer to the new set of backends
([demo app](https://github.com/cilium/cilium/pull/30036/files#diff-888b31f33198e7ac2cfc535e0903c2e588d1e80e0fcb7f566cdbaa701642c01cR66)
shows how this can be implemented).

### Key Question: Reconciliation of "Service"

TODO can the reconciliation of the BPF maps (services, backends, maglev, etc.) be correctly and efficiently
implemented solely against a "Service" object? Idea essentially would be to have a single "Update" operation
that takes a "Service" object and does, in order, BPF batch update of backends, maglev and then services maps.
On failure all these operations would be retried as a single unit. Since backends may be reused by multiple
services a simple memoization of backend updates can be implemented to avoid an unnecessary update of the backends map.

![low-level](lowlevel.svg)

## Future Milestones

_List things that this CFP will enable but that are out of scope for now. This can help understand the greater impact of a proposal without requiring to extend the scope of a CFP unnecessarily._

### Deferred Milestone 1

_Description of deferred milestone_

### Deferred Milestone 2

