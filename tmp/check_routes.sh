#!/bin/bash
bash -lc 'pm2 logs changji-api --lines 100 --nostream' | grep "Mapped"
