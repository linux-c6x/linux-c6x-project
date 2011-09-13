#!/bin/bash

# post build script for release-build

# for LTP release bundles, the kernel builds are needed to syslink-all but
# should not be included in the release bundle
rm -f ../product/vmlinux* ../product/modules* || true

