usage: cts-win.exe [--help] [--tls] [-p/--port <port>] [-cert <path>] [-key <key>] [-r/--cam <camera id>] [-m/--meta <meta id>]

Argument usage:
   --help, -h        Bring up help menu
   --tls             Enables TLS mode (if this parameter is passed, then cert and key must be provided, otherwise the server works in non-TLS mode)
   --port, -p        Port to listen to
   --cert, -c        Path to root certificate file
   --key, -k         Path to private key file
   --cam, -r         Camera type (0 - Auto, 1 - ADAS, 2 - DUALCAM, 3 - DSM)
   --meta, -m        Metadata (0 - No metadata, 1 - Before file download)

---------------------------------------------------------------------------------------------------------------------------------------------------
Linux release notes:
- Please make sure that FFMPEG is available
---------------------------------------------------------------------------------------------------------------------------------------------------
CHANGELOG
---------------------------------------------------------------------------------------------------------------------------------------------------
0.2.3 - 2022.11.25 - Added DSM metadata support
0.2.2 - 2022.10.27 - Added DSM footage support
0.2.1 - 2022.10.10 - Added human-readable metadata print
0.2.0 - 2022.10.04 - Improved server stability, prepared the server source to be provided to clients
0.1.4 - 2022.08.22 - Fixed ADAS metadata request
0.1.3 - 2022.08.11 - Added ADAS metadata support
0.1.2 - 2022.06.16 - Updated metadata parsing
0.1.1 - 2022.05.10 - Added DualCam footage metadata support
0.1.0 - 2022.02.25 - Added ADAS footage support
0.0.2 - 2021.06.10 - TLS support + turn off verbose mode
0.0.1 - 2020.06.17 - Initial implementation
