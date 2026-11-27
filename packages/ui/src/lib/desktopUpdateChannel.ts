import { canUseElectronDesktopIPC, invokeDesktop, isDesktopLocalOriginActive } from './desktop';
import { loadDesktopSettings } from './persistence';
import { isUpdateChannel, parseCanaryVersion, type UpdateChannel } from './updateChannel';

type UpdateChannelStatus = { channel?: string; canarySupported?: boolean };

type DesktopUpdateChannelStatus = {
  channel: UpdateChannel | null;
  canarySupported: boolean;
};

const parseUpdateChannelStatus = (result: UpdateChannelStatus | null): DesktopUpdateChannelStatus | null => {
  const channel = isUpdateChannel(result?.channel) ? result.channel : null;
  if (!channel) return null;
  return {
    channel,
    canarySupported: result?.canarySupported !== false,
  };
};

export const getDesktopUpdateChannelStatus = async (): Promise<DesktopUpdateChannelStatus | null> => {
  if (!canUseElectronDesktopIPC() || !isDesktopLocalOriginActive()) {
    return null;
  }

  try {
    return parseUpdateChannelStatus(await invokeDesktop<UpdateChannelStatus>('desktop_get_update_channel'));
  } catch (error) {
    console.warn('Failed to get the update channel', error);
    return null;
  }
};

export const loadServerUpdateChannel = async (serverVersion: string): Promise<UpdateChannel | null> => {
  const settings = await loadDesktopSettings();
  if (!settings) return null;
  return settings.serverUpdateChannel ?? (parseCanaryVersion(serverVersion) ? 'canary' : 'stable');
};
