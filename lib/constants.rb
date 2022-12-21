# frozen_string_literal: true

require_relative 'string_colors'

SCREEN_WIDTH = 88
DIVIDER = '-' * SCREEN_WIDTH
LINE = '='.light_blue * SCREEN_WIDTH

AUDIT_PATH = File.join(File.dirname(__FILE__), '../audit_reports')
CACHE_PATH = File.join(File.dirname(__FILE__), '../cache')
CONFIG     = YAML.safe_load(File.read("#{File.dirname(__FILE__)}/../config/config.yaml"))

EC2_LEGEND  = '   Green: Running'.go + '   Yellow: Stopped'.warning + '   Red: Terminated'.off
EKS_LEGEND  = '   Grn: Active/Creating'.go +
              '  Yel: Pend/Updat/Deleting'.warning +
              '  Red: Failed'.off
KMS_LEGEND  = '   Green: Enabled'.go + '   Yellow: No rotation'.warning + '   Red: Disabled'.off
S3_LEGEND   = '   Green: Encrypted'.go + '   Yellow: No logging'.warning + '   Red: Unencrypted'.off
SNAP_LEGEND = '   Green: Encrypted'.go + '   Red: Unencrypted'.off
USER_LEGEND = '   Green: MFA set / fresh key'.go + '   Yellow: Stale or no access key'.warning +
              '   Red: No MFA configured'.off
VOL_LEGEND  = '   Green: Encrypted'.go + '   Yellow: Available'.warning + '   Red: Unencrypted'.off
