#!/bin/bash
clickable clean --arch arm64
clickable clean --arch armhf
clickable clean --arch amd64

clickable build --arch arm64
clickable build --arch armhf
clickable build --arch amd64
