NAME_FORMAT = /\A[A-Za-z\d\-\_]*\z/
ENDPOINT_TOKEN_REGEN_RANDOM = 5
MAX_PACKED_FILE_SIZE = 1.gigabyte
MAX_PACKED_FILE_COUNT = 100000
MAX_ICON_SIZE = 1.megabyte
MAX_FILE_SIZE = 4.gigabytes
MAX_DESCRIPTION_LENGTH = 2048
MAX_VERSION_LENGTH = 16
MIN_NAME_LENGTH = 3
MAX_NAME_LENGTH = 100
MODEL_CACHE_TIMEOUT = 15.minutes # TODO: Increase
JOB_TIMEOUT = 5.minutes

RESTRICTED_NAMES = %w[
  setting    sign_in       api
  settings   sign_out      actuator
  page       file
  pages      files
  source     test
  sources    admin
  package    console
  packages   wp-admin
  user       _ignition
  users      autodiscover
  endpoint   mifs
  endpoints  vendor
]
