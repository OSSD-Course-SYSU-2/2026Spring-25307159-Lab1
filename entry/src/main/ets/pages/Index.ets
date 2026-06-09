interface Point {
  x: number;
  y: number;
}

interface Item {
  pos: Point;
  type: string;
  timer: number;
}

interface GameSaveData {
  snake: Point[];
  food: Point;
  items: Item[];
  direction: string;
  score: number;
  highScore: number;
  speed: number;
  gameState: string;
  walls: Point[];
  level: number;
  shieldTurns: number;
}

@Entry
@Component
struct Index {
  private readonly INITIAL_SPEED: number = 160;
  private readonly MIN_SPEED: number = 60;
  private readonly SPEED_STEP: number = 2;
  private readonly ITEM_SPAWN_INTERVAL: number = 8;
  private readonly ITEM_LIFETIME: number = 50;
  private readonly MAX_ITEMS: number = 3;

  @State gameState: string = 'IDLE';
  @State score: number = 0;
  @State highScore: number = 0;
  @State snake: Point[] = [];
  @State food: Point = { x: 0, y: 0 };
  @State items: Item[] = [];
  @State walls: Point[] = [];
  @State snakeDirection: string = 'RIGHT';
  @State currentSpeed: number = 160;
  @State gridSize: number = 18;
  @State cellSize: number = 16;
  @State isTablet: boolean = false;
  @State deviceTypeLabel: string = '手机';
  @State level: number = 1;
  @State shieldTurns: number = 0;
  @State moveCount: number = 0;
  @State canvasW: number = 288;
  @State canvasH: number = 288;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private gameInterval: number = -1;
  private nextDirection: string = 'RIGHT';

  aboutToAppear(): void {
    this.detectDevice();
    this.initGame();
    this.tryRestoreData();
  }

  aboutToDisappear(): void {
    this.stopGame();
  }

  private detectDevice(): void {
    this.isTablet = false;
    this.gridSize = 18;
    this.cellSize = 16;
    this.deviceTypeLabel = '手机';
    this.canvasW = this.gridSize * this.cellSize;
    this.canvasH = this.gridSize * this.cellSize;
  }

  private tryRestoreData(): void {
    const restoreData = AppStorage.get<string>('restoreGameData');
    if (restoreData) {
      try {
        const data: GameSaveData = JSON.parse(restoreData) as GameSaveData;
        this.snake = data.snake;
        this.food = data.food;
        this.items = data.items ?? [];
        this.walls = data.walls ?? [];
        this.snakeDirection = data.direction;
        this.nextDirection = data.direction;
        this.score = data.score;
        this.highScore = data.highScore;
        this.currentSpeed = data.speed;
        this.gameState = data.gameState;
        this.level = data.level ?? 1;
        this.shieldTurns = data.shieldTurns ?? 0;
        AppStorage.delete('restoreGameData');
        if (this.gameState === 'PLAYING') {
          this.startTimer();
        }
      } catch (e) {
        this.initGame();
      }
    }
  }

  private initGame(): void {
    const cx = Math.floor(this.gridSize / 2);
    const cy = Math.floor(this.gridSize / 2);
    this.snake = [
      { x: cx, y: cy },
      { x: cx - 1, y: cy },
      { x: cx - 2, y: cy }
    ];
    this.snakeDirection = 'RIGHT';
    this.nextDirection = 'RIGHT';
    this.score = 0;
    this.currentSpeed = this.INITIAL_SPEED;
    this.level = 1;
    this.shieldTurns = 0;
    this.moveCount = 0;
    this.items = [];
    this.walls = [];
    this.generateFood();
    this.generateWalls();
  }

  private generateWalls(): void {
    this.walls = [];
    const wallCount = this.level * 4;
    const occupied = new Set<string>();
    this.snake.forEach(p => occupied.add(`${p.x},${p.y}`));
    occupied.add(`${this.food.x},${this.food.y}`);
    const cx = Math.floor(this.gridSize / 2);
    const cy = Math.floor(this.gridSize / 2);
    for (let dx = -3; dx <= 3; dx++) {
      for (let dy = -3; dy <= 3; dy++) {
        occupied.add(`${cx + dx},${cy + dy}`);
      }
    }
    for (let i = 0; i < wallCount; i++) {
      let wx: number = 0;
      let wy: number = 0;
      let attempts = 0;
      do {
        wx = Math.floor(Math.random() * (this.gridSize - 2)) + 1;
        wy = Math.floor(Math.random() * (this.gridSize - 2)) + 1;
        attempts++;
      } while (occupied.has(`${wx},${wy}`) && attempts < 100);
      if (attempts < 100) {
        this.walls.push({ x: wx, y: wy });
        occupied.add(`${wx},${wy}`);
      }
    }
  }

  private generateFood(): void {
    let newFood: Point;
    do {
      newFood = {
        x: Math.floor(Math.random() * this.gridSize),
        y: Math.floor(Math.random() * this.gridSize)
      };
    } while (this.isOccupied(newFood));
    this.food = newFood;
  }

  private isOccupied(point: Point): boolean {
    if (this.snake.some(s => s.x === point.x && s.y === point.y)) return true;
    if (this.walls.some(w => w.x === point.x && w.y === point.y)) return true;
    if (this.items.some(it => it.pos.x === point.x && it.pos.y === point.y)) return true;
    return false;
  }

  private isOnWall(point: Point): boolean {
    return this.walls.some(w => w.x === point.x && w.y === point.y);
  }

  private spawnItem(): void {
    if (this.items.length >= this.MAX_ITEMS) return;
    const types: string[] = ['speed', 'slow', 'double', 'shield', 'shrink'];
    const type: string = types[Math.floor(Math.random() * types.length)];
    let pos: Point;
    let attempts = 0;
    do {
      pos = {
        x: Math.floor(Math.random() * this.gridSize),
        y: Math.floor(Math.random() * this.gridSize)
      };
      attempts++;
    } while (this.isOccupied(pos) && attempts < 100);
    if (attempts < 100) {
      const newItem: Item = { pos: pos, type: type, timer: this.ITEM_LIFETIME };
      this.items.push(newItem);
    }
  }

  private applyItem(type: string): void {
    if (type === 'speed') {
      if (this.currentSpeed > this.MIN_SPEED + 20) {
        this.currentSpeed -= 15;
        this.startTimer();
      }
    } else if (type === 'slow') {
      this.currentSpeed = Math.min(this.currentSpeed + 30, 250);
      this.startTimer();
    } else if (type === 'double') {
      this.score += 20;
    } else if (type === 'shield') {
      this.shieldTurns = 5;
    } else if (type === 'shrink') {
      if (this.snake.length > 3) {
        const removeCount = Math.min(3, this.snake.length - 3);
        this.snake = this.snake.slice(0, this.snake.length - removeCount);
      }
    }
  }

  private startGame(): void {
    if (this.gameState === 'PLAYING') return;
    if (this.gameState === 'OVER' || this.gameState === 'IDLE') {
      this.initGame();
      this.drawGame();
    }
    this.gameState = 'PLAYING';
    this.startTimer();
  }

  private startTimer(): void {
    this.stopGame();
    this.gameInterval = setInterval(() => {
      this.gameLoop();
    }, this.currentSpeed);
  }

  private pauseGame(): void {
    if (this.gameState !== 'PLAYING') return;
    this.stopGame();
    this.gameState = 'PAUSED';
  }

  private stopGame(): void {
    if (this.gameInterval !== -1) {
      clearInterval(this.gameInterval);
      this.gameInterval = -1;
    }
  }

  private gameLoop(): void {
    this.snakeDirection = this.nextDirection;
    this.moveCount++;
    const updatedItems: Item[] = [];
    for (let i = 0; i < this.items.length; i++) {
      const it = this.items[i];
      const ni: Item = { pos: it.pos, type: it.type, timer: it.timer - 1 };
      if (ni.timer > 0) {
        updatedItems.push(ni);
      }
    }
    this.items = updatedItems;
    if (this.moveCount % this.ITEM_SPAWN_INTERVAL === 0) {
      this.spawnItem();
    }
    this.moveSnake();
    this.checkCollision();
    this.drawGame();
  }

  private moveSnake(): void {
    const head = this.snake[0];
    let newHead: Point;
    if (this.snakeDirection === 'UP') {
      newHead = { x: head.x, y: head.y - 1 };
    } else if (this.snakeDirection === 'DOWN') {
      newHead = { x: head.x, y: head.y + 1 };
    } else if (this.snakeDirection === 'LEFT') {
      newHead = { x: head.x - 1, y: head.y };
    } else {
      newHead = { x: head.x + 1, y: head.y };
    }
    this.snake.unshift(newHead);
    if (newHead.x === this.food.x && newHead.y === this.food.y) {
      this.score += 10;
      if (this.score > this.highScore) {
        this.highScore = this.score;
      }
      const newLevel = Math.floor(this.score / 100) + 1;
      if (newLevel > this.level) {
        this.level = newLevel;
        this.generateWalls();
      }
      this.generateFood();
      if (this.currentSpeed > this.MIN_SPEED) {
        this.currentSpeed -= this.SPEED_STEP;
        this.startTimer();
      }
    } else {
      this.snake.pop();
    }
    const hitItem = this.items.find(it => it.pos.x === newHead.x && it.pos.y === newHead.y);
    if (hitItem) {
      this.applyItem(hitItem.type);
      this.items = this.items.filter(it => it !== hitItem);
    }
    if (this.shieldTurns > 0) {
      this.shieldTurns--;
    }
  }

  private checkCollision(): void {
    let head = this.snake[0];
    if (head.x < 0 || head.x >= this.gridSize || head.y < 0 || head.y >= this.gridSize) {
      if (this.shieldTurns > 0) {
        this.shieldTurns = 0;
        let nx = head.x;
        let ny = head.y;
        if (nx < 0) nx = this.gridSize - 1;
        else if (nx >= this.gridSize) nx = 0;
        if (ny < 0) ny = this.gridSize - 1;
        else if (ny >= this.gridSize) ny = 0;
        const nh: Point = { x: nx, y: ny };
        this.snake[0] = nh;
        head = nh;
      } else {
        this.gameOver();
        return;
      }
    }
    if (this.isOnWall(head)) {
      if (this.shieldTurns > 0) {
        this.shieldTurns = 0;
      } else {
        this.gameOver();
        return;
      }
    }
    for (let i = 1; i < this.snake.length; i++) {
      if (head.x === this.snake[i].x && head.y === this.snake[i].y) {
        if (this.shieldTurns > 0) {
          this.shieldTurns = 0;
        } else {
          this.gameOver();
          return;
        }
      }
    }
  }

  private gameOver(): void {
    this.stopGame();
    this.gameState = 'OVER';
  }

  private drawGame(): void {
    if (!this.context) return;
    this.context.clearRect(0, 0, this.canvasW, this.canvasH);
    this.drawBackground();
    this.drawGrid();
    this.drawWalls();
    this.drawItems();
    this.drawFood();
    this.drawSnake();
  }

  private drawBackground(): void {
    this.context.fillStyle = '#0d0d1a';
    this.context.fillRect(0, 0, this.canvasW, this.canvasH);
  }

  private drawGrid(): void {
    this.context.strokeStyle = 'rgba(255,255,255,0.03)';
    this.context.lineWidth = 0.5;
    for (let i = 1; i < this.gridSize; i++) {
      this.context.beginPath();
      this.context.moveTo(i * this.cellSize, 0);
      this.context.lineTo(i * this.cellSize, this.canvasH);
      this.context.stroke();
      this.context.beginPath();
      this.context.moveTo(0, i * this.cellSize);
      this.context.lineTo(this.canvasW, i * this.cellSize);
      this.context.stroke();
    }
  }

  private drawWalls(): void {
    this.walls.forEach(w => {
      const x = w.x * this.cellSize;
      const y = w.y * this.cellSize;
      this.context.fillStyle = '#3a3a5c';
      this.context.fillRect(x + 1, y + 1, this.cellSize - 2, this.cellSize - 2);
      this.context.strokeStyle = '#5a5a8c';
      this.context.lineWidth = 0.5;
      this.context.strokeRect(x + 1, y + 1, this.cellSize - 2, this.cellSize - 2);
    });
  }

  private drawSnake(): void {
    this.snake.forEach((segment, index) => {
      const x = segment.x * this.cellSize;
      const y = segment.y * this.cellSize;
      const pad = index === 0 ? 1 : 2;
      if (index === 0) {
        if (this.shieldTurns > 0) {
          this.context.fillStyle = '#ffd700';
        } else {
          this.context.fillStyle = '#00d4ff';
        }
        this.context.fillRect(x + pad, y + pad, this.cellSize - pad * 2, this.cellSize - pad * 2);
        this.context.fillStyle = '#ffffff';
        const eyeSize = 2;
        if (this.snakeDirection === 'RIGHT') {
          this.context.fillRect(x + this.cellSize - 5, y + 4, eyeSize, eyeSize);
          this.context.fillRect(x + this.cellSize - 5, y + this.cellSize - 6, eyeSize, eyeSize);
        } else if (this.snakeDirection === 'LEFT') {
          this.context.fillRect(x + 3, y + 4, eyeSize, eyeSize);
          this.context.fillRect(x + 3, y + this.cellSize - 6, eyeSize, eyeSize);
        } else if (this.snakeDirection === 'UP') {
          this.context.fillRect(x + 4, y + 3, eyeSize, eyeSize);
          this.context.fillRect(x + this.cellSize - 6, y + 3, eyeSize, eyeSize);
        } else {
          this.context.fillRect(x + 4, y + this.cellSize - 5, eyeSize, eyeSize);
          this.context.fillRect(x + this.cellSize - 6, y + this.cellSize - 5, eyeSize, eyeSize);
        }
      } else {
        const t = index / this.snake.length;
        const g = Math.round(212 - t * 100);
        const b = Math.round(255 - t * 100);
        this.context.fillStyle = `rgb(0,${g},${b})`;
        this.context.fillRect(x + pad, y + pad, this.cellSize - pad * 2, this.cellSize - pad * 2);
      }
    });
  }

  private drawFood(): void {
    const x = this.food.x * this.cellSize;
    const y = this.food.y * this.cellSize;
    this.context.fillStyle = '#ff4da6';
    this.context.beginPath();
    this.context.arc(x + this.cellSize / 2, y + this.cellSize / 2, this.cellSize / 2 - 2, 0, 2 * Math.PI);
    this.context.fill();
  }

  private getItemColor(type: string): string {
    if (type === 'speed') return '#ff6600';
    if (type === 'slow') return '#66ff66';
    if (type === 'double') return '#ffff00';
    if (type === 'shield') return '#ffd700';
    if (type === 'shrink') return '#cc66ff';
    return '#ffffff';
  }

  private getItemSymbol(type: string): string {
    if (type === 'speed') return 'S';
    if (type === 'slow') return 'W';
    if (type === 'double') return '2';
    if (type === 'shield') return 'D';
    if (type === 'shrink') return 'X';
    return '?';
  }

  private drawItems(): void {
    this.items.forEach(item => {
      const x = item.pos.x * this.cellSize;
      const y = item.pos.y * this.cellSize;
      const alpha = Math.min(1, item.timer / 10);
      const color = this.getItemColor(item.type);
      this.context.save();
      this.context.globalAlpha = alpha;
      this.context.fillStyle = color;
      this.context.beginPath();
      this.context.arc(x + this.cellSize / 2, y + this.cellSize / 2, this.cellSize / 2 - 1, 0, 2 * Math.PI);
      this.context.fill();
      this.context.fillStyle = '#000000';
      this.context.font = `bold ${Math.floor(this.cellSize * 0.6)}px sans-serif`;
      this.context.textAlign = 'center';
      this.context.textBaseline = 'middle';
      this.context.fillText(this.getItemSymbol(item.type), x + this.cellSize / 2, y + this.cellSize / 2);
      this.context.restore();
    });
  }

  private changeDirection(newDirection: string): void {
    if (this.gameState !== 'PLAYING') return;
    let isOpposite = false;
    if (newDirection === 'UP' && this.snakeDirection === 'DOWN') isOpposite = true;
    if (newDirection === 'DOWN' && this.snakeDirection === 'UP') isOpposite = true;
    if (newDirection === 'LEFT' && this.snakeDirection === 'RIGHT') isOpposite = true;
    if (newDirection === 'RIGHT' && this.snakeDirection === 'LEFT') isOpposite = true;
    if (!isOpposite) {
      this.nextDirection = newDirection;
    }
  }

  build() {
    Column() {
      Row() {
        Text('贪吃蛇')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00d4ff')
          .margin({ right: 8 })
        Text(`[${this.deviceTypeLabel}]`)
          .fontSize(10)
          .fontColor('rgba(0,212,255,0.5)')
          .margin({ right: 6 })
        Text(`Lv.${this.level}`)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#ffd700')
          .margin({ right: 6 })
        if (this.shieldTurns > 0) {
          Text('🛡')
            .fontSize(12)
            .margin({ right: 6 })
        }
        Blank()
        Text(`${this.score}`)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00d4ff')
          .margin({ right: 8 })
        Text(`最高:${this.highScore}`)
          .fontSize(11)
          .fontColor('#ff4da6')
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 4 })

      Stack() {
        Canvas(this.context)
          .width('100%')
          .height('100%')
          .onReady(() => {
            const w = this.context.width;
            const h = this.context.height;
            this.canvasW = w;
            this.canvasH = h;
            this.cellSize = Math.floor(Math.min(w, h) / this.gridSize);
            this.drawGame();
          })
        if (this.gameState !== 'PLAYING') {
          Column() {
            if (this.gameState === 'OVER') {
              Text('游戏结束')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ff4da6')
                .margin({ bottom: 6 })
              Text(`${this.score}`)
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ff4da6')
                .margin({ bottom: 6 })
              Text(`等级 Lv.${this.level}`)
                .fontSize(14)
                .fontColor('rgba(255,77,166,0.7)')
                .margin({ bottom: 12 })
            } else {
              Text('贪吃蛇')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .fontColor('#00d4ff')
                .margin({ bottom: 8 })
              Column() {
                Text('S加速  W减速  2双倍分').fontSize(10).fontColor('rgba(255,255,255,0.35)')
                Text('D护盾  X缩短').fontSize(10).fontColor('rgba(255,255,255,0.35)')
              }
              .margin({ bottom: 12 })
            }
            Button(this.gameState === 'OVER' ? '再来一局' : '开始游戏')
              .width(120)
              .height(40)
              .fontSize(15)
              .fontColor('#ffffff')
              .backgroundColor('#00d4ff')
              .borderRadius(8)
              .onClick(() => this.startGame())
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(10,10,20,0.88)')
        }
      }
      .layoutWeight(1)
      .border({ width: 2, color: '#00d4ff' })
      .margin({ top: 4 })

      Row() {
        if (this.gameState === 'PLAYING') {
          Button('暂停')
            .width(60).height(28).fontSize(12)
            .fontColor('#ffffff').backgroundColor('#ff9800').borderRadius(6)
            .onClick(() => this.pauseGame())
        } else if (this.gameState === 'PAUSED') {
          Button('继续')
            .width(60).height(28).fontSize(12)
            .fontColor('#ffffff').backgroundColor('#4CAF50').borderRadius(6)
            .onClick(() => this.startGame())
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 6 })

      Column() {
        Button('▲')
          .width(44).height(44).fontSize(18)
          .backgroundColor('rgba(0,212,255,0.1)').fontColor('#00d4ff')
          .border({ width: 1, color: '#00d4ff' }).borderRadius(6)
          .onClick(() => this.changeDirection('UP'))
        Row() {
          Button('◄')
            .width(44).height(44).fontSize(18)
            .backgroundColor('rgba(0,212,255,0.1)').fontColor('#00d4ff')
            .border({ width: 1, color: '#00d4ff' }).borderRadius(6)
            .onClick(() => this.changeDirection('LEFT'))
          Blank().width(44)
          Button('►')
            .width(44).height(44).fontSize(18)
            .backgroundColor('rgba(0,212,255,0.1)').fontColor('#00d4ff')
            .border({ width: 1, color: '#00d4ff' }).borderRadius(6)
            .onClick(() => this.changeDirection('RIGHT'))
        }
        .width(132).margin({ top: 4, bottom: 4 })
        Button('▼')
          .width(44).height(44).fontSize(18)
          .backgroundColor('rgba(0,212,255,0.1)').fontColor('#00d4ff')
          .border({ width: 1, color: '#00d4ff' }).borderRadius(6)
          .onClick(() => this.changeDirection('DOWN'))
      }
      .margin({ top: 4 })

      Row() {
        Text('一次开发 · 多端部署 · 自由流转')
          .fontSize(9).fontColor('rgba(255,255,255,0.2)')
      }
      .margin({ top: 6, bottom: 4 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a0a14')
    .alignItems(HorizontalAlign.Center)
  }
}
