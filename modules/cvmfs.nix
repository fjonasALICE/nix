{ ... }: {

  # ── CernVM-FS ───────────────────────────────────────────────────────────────
  # Installs cvmfs and fuse-t via Homebrew and configures automatic mounting.
  #
  # Repositories are mounted via a LaunchDaemon because macOS has no autofs.
  # After the first `darwin-rebuild switch`, trigger the daemon once manually:
  #   sudo launchctl start ch.cern.cvmfs.mount
  # On subsequent reboots it runs automatically at boot.
  # Verify with: cvmfs_config probe

  homebrew.taps = [
    "macos-fuse-t/cask"
    "cvmfs/homebrew-cvmfs"
  ];

  homebrew.casks = [
    "macos-fuse-t/cask/fuse-t"
    "cvmfs/homebrew-cvmfs/cvmfs"
  ];

  # CVMFS_CLIENT_PROFILE=single disables the requirement for a site HTTP proxy.
  environment.etc."cvmfs/default.local".text = ''
    CVMFS_REPOSITORIES=cvmfs-config.cern.ch,alice.cern.ch,sft.cern.ch
    CVMFS_CLIENT_PROFILE=single
    CVMFS_HTTP_PROXY=DIRECT
  '';

  # Mounts the config repo first (required for certificate/config lookup),
  # then the data repos. Idempotent: skips repos already mounted.
  launchd.daemons.cvmfs-mount = {
    serviceConfig = {
      Label = "ch.cern.cvmfs.mount";
      ProgramArguments = [
        "/bin/sh" "-c"
        ''
          mount_repo() {
            mkdir -p "/cvmfs/$1"
            mount | grep -q "/cvmfs/$1" || mount -t cvmfs "$1" "/cvmfs/$1"
          }
          mount_repo cvmfs-config.cern.ch
          mount_repo alice.cern.ch
          mount_repo sft.cern.ch
        ''
      ];
      RunAtLoad = true;
      StandardOutPath = "/var/log/cvmfs-mount.log";
      StandardErrorPath = "/var/log/cvmfs-mount.log";
    };
  };
}
