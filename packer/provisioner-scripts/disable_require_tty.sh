#!/bin/bash

sudo sed -i 's/Defaults    requiretty/Defaults    !requiretty/g' /etc/sudoers

