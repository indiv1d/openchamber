import { useEffect, useState } from 'react';
import { getDesktopUpdateChannelStatus, loadServerUpdateChannel } from '@/lib/desktopUpdateChannel';
import type { UpdateChannel } from '@/lib/updateChannel';

type Args = {
  isDesktopApp: boolean;
  isNpmServer: boolean;
  serverVersion: string | null;
};

export const useUpdateChannelChoice = ({ isDesktopApp, isNpmServer, serverVersion }: Args) => {
  const [updateChannel, setUpdateChannel] = useState<UpdateChannel | null>(null);
  const [canarySupported, setCanarySupported] = useState(true);

  useEffect(() => {
    if (!isDesktopApp && !isNpmServer) return;
    let cancelled = false;
    const load = async () => {
      if (isDesktopApp) {
        const status = await getDesktopUpdateChannelStatus();
        if (!cancelled) {
          setUpdateChannel(status?.channel ?? null);
          setCanarySupported(status?.canarySupported !== false);
        }
        return;
      }
      const channel = await loadServerUpdateChannel(serverVersion ?? '');
      if (!cancelled) setUpdateChannel(channel);
    };
    void load();
    return () => {
      cancelled = true;
    };
  }, [isDesktopApp, isNpmServer, serverVersion]);

  return { updateChannel, canarySupported, setUpdateChannel };
};
