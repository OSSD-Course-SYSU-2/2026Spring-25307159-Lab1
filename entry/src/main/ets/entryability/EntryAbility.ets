import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { AbilityDelegatorRegistry } from '@kit.TestKit';

const DOMAIN = 0x0000;
const TAG = 'SnakeGame';

interface GameContinueData {
  snake: Array<{ x: number; y: number }>;
  food: { x: number; y: number };
  direction: string;
  score: number;
  highScore: number;
  speed: number;
  gameState: string;
}

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onBackground');
  }

  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onContinue');

    const gameDataStr = wantParam['gameData'] as string;
    if (gameDataStr) {
      hilog.info(DOMAIN, TAG, 'onContinue with game data: %{public}s', gameDataStr);
      return AbilityConstant.OnContinueResult.AGREE;
    }

    hilog.info(DOMAIN, TAG, 'onContinue without game data, agree to migrate');
    return AbilityConstant.OnContinueResult.AGREE;
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onNewWant');
    if (want.parameters) {
      const gameDataStr = want.parameters['gameData'] as string;
      if (gameDataStr) {
        hilog.info(DOMAIN, TAG, 'Restore game data from onNewWant: %{public}s', gameDataStr);
        AppStorage.setOrCreate<string>('restoreGameData', gameDataStr);
      }
    }
  }

  onRestoreData(want: Want): void {
    hilog.info(DOMAIN, TAG, '%{public}s', 'Ability onRestoreData');
    if (want.parameters) {
      const gameDataStr = want.parameters['gameData'] as string;
      if (gameDataStr) {
        hilog.info(DOMAIN, TAG, 'Restore game data: %{public}s', gameDataStr);
        AppStorage.setOrCreate<string>('restoreGameData', gameDataStr);
      }
    }
  }

  onConfigurationChange(newConfig: ConfigurationConstant.Configuration): void {
    hilog.info(DOMAIN, TAG, 'Ability onConfigurationChange: %{public}s', JSON.stringify(newConfig));
  }

  onMemoryLevel(level: AbilityConstant.MemoryLevel): void {
    hilog.info(DOMAIN, TAG, 'Ability onMemoryLevel: %{public}d', level);
  }
}
