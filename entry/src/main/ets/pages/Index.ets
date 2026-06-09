interface Point {
  x: number;
  y: number;
}

@Entry
@Component
struct Index {
  private readonly GRID_SIZE: number = 20;
  private readonly CELL_SIZE: number = 18;
  private readonly INITIAL_SPEED: number = 180;
  private readonly MIN_SPEED: number = 80;
  private readonly SPEED_STEP: number = 3;

  @State gameState: string = 'IDLE';
  @State score: number = 0;
  @State highScore: number = 0;
  @State snake: Point[] = [];
  @State food: Point = { x: 0, y: 0 };
  @State snakeDirection: string = 'RIGHT';
  @State currentSpeed: number = 180;

  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  private gameInterval: number = -1;
  private canvasWidth: number = 20 * 18;
  private canvasHeight: number = 20 * 18;
  private nextDirection: string = 'RIGHT';

  aboutToAppear(): void {
    this.initGame();
  }

  aboutToDisappear(): void {
    this.stopGame();
  }

  private initGame(): void {
    this.snake = [
      { x: 10, y: 10 },
      { x: 9, y: 10 },
      { x: 8, y: 10 }
    ];
    this.snakeDirection = 'RIGHT';
    this.nextDirection = 'RIGHT';
    this.score = 0;
    this.currentSpeed = this.INITIAL_SPEED;
    this.generateFood();
  }

  private generateFood(): void {
    let newFood: Point;
    do {
      newFood = {
        x: Math.floor(Math.random() * this.GRID_SIZE),
        y: Math.floor(Math.random() * this.GRID_SIZE)
      };
    } while (this.isOnSnake(newFood));
    this.food = newFood;
  }

  private isOnSnake(point: Point): boolean {
    return this.snake.some(segment => segment.x === point.x && segment.y === point.y);
  }

  private startGame(): void {
    if (this.gameState === 'PLAYING') return;
    if (this.gameState === 'OVER' || this.gameState === 'IDLE') {
      this.initGame();
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
      this.generateFood();
      if (this.currentSpeed > this.MIN_SPEED) {
        this.currentSpeed -= this.SPEED_STEP;
        this.startTimer();
      }
    } else {
      this.snake.pop();
    }
  }

  private checkCollision(): void {
    const head = this.snake[0];
    if (head.x < 0 || head.x >= this.GRID_SIZE || head.y < 0 || head.y >= this.GRID_SIZE) {
      this.gameOver();
      return;
    }
    for (let i = 1; i < this.snake.length; i++) {
      if (head.x === this.snake[i].x && head.y === this.snake[i].y) {
        this.gameOver();
        return;
      }
    }
  }

  private gameOver(): void {
    this.stopGame();
    this.gameState = 'OVER';
  }

  private drawGame(): void {
    if (!this.context) return;
    this.context.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
    this.drawBackground();
    this.drawGrid();
    this.drawFood();
    this.drawSnake();
  }

  private drawBackground(): void {
    this.context.fillStyle = '#0d0d1a';
    this.context.fillRect(0, 0, this.canvasWidth, this.canvasHeight);
  }

  private drawGrid(): void {
    this.context.strokeStyle = 'rgba(255,255,255,0.04)';
    this.context.lineWidth = 0.5;
    for (let i = 1; i < this.GRID_SIZE; i++) {
      this.context.beginPath();
      this.context.moveTo(i * this.CELL_SIZE, 0);
      this.context.lineTo(i * this.CELL_SIZE, this.canvasHeight);
      this.context.stroke();
      this.context.beginPath();
      this.context.moveTo(0, i * this.CELL_SIZE);
      this.context.lineTo(this.canvasWidth, i * this.CELL_SIZE);
      this.context.stroke();
    }
  }

  private drawSnake(): void {
    this.snake.forEach((segment, index) => {
      const x = segment.x * this.CELL_SIZE;
      const y = segment.y * this.CELL_SIZE;
      const pad = index === 0 ? 1 : 2;

      if (index === 0) {
        this.context.fillStyle = '#00d4ff';
        this.context.fillRect(x + pad, y + pad, this.CELL_SIZE - pad * 2, this.CELL_SIZE - pad * 2);
        this.context.fillStyle = '#ffffff';
        const eyeSize = 2;
        if (this.snakeDirection === 'RIGHT') {
          this.context.fillRect(x + this.CELL_SIZE - 5, y + 4, eyeSize, eyeSize);
          this.context.fillRect(x + this.CELL_SIZE - 5, y + this.CELL_SIZE - 6, eyeSize, eyeSize);
        } else if (this.snakeDirection === 'LEFT') {
          this.context.fillRect(x + 3, y + 4, eyeSize, eyeSize);
          this.context.fillRect(x + 3, y + this.CELL_SIZE - 6, eyeSize, eyeSize);
        } else if (this.snakeDirection === 'UP') {
          this.context.fillRect(x + 4, y + 3, eyeSize, eyeSize);
          this.context.fillRect(x + this.CELL_SIZE - 6, y + 3, eyeSize, eyeSize);
        } else {
          this.context.fillRect(x + 4, y + this.CELL_SIZE - 5, eyeSize, eyeSize);
          this.context.fillRect(x + this.CELL_SIZE - 6, y + this.CELL_SIZE - 5, eyeSize, eyeSize);
        }
      } else {
        const t = index / this.snake.length;
        const g = Math.round(212 - t * 100);
        const b = Math.round(255 - t * 100);
        this.context.fillStyle = `rgb(0,${g},${b})`;
        this.context.fillRect(x + pad, y + pad, this.CELL_SIZE - pad * 2, this.CELL_SIZE - pad * 2);
      }
    });
  }

  private drawFood(): void {
    const x = this.food.x * this.CELL_SIZE;
    const y = this.food.y * this.CELL_SIZE;
    this.context.fillStyle = '#ff4da6';
    this.context.beginPath();
    this.context.arc(
      x + this.CELL_SIZE / 2,
      y + this.CELL_SIZE / 2,
      this.CELL_SIZE / 2 - 2,
      0,
      2 * Math.PI
    );
    this.context.fill();
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
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00d4ff')
          .margin({ right: 20 })

        Blank()

        Text(`分数: ${this.score}`)
          .fontSize(16)
          .fontColor('#00d4ff')
          .margin({ right: 16 })

        Text(`最高: ${this.highScore}`)
          .fontSize(16)
          .fontColor('#ff4da6')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 8 })

      Stack() {
        Canvas(this.context)
          .width(this.canvasWidth)
          .height(this.canvasHeight)
          .onReady(() => {
            this.drawGame();
          })

        if (this.gameState !== 'PLAYING') {
          Column() {
            if (this.gameState === 'OVER') {
              Text('游戏结束')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ff4da6')
                .margin({ bottom: 8 })

              Text(`${this.score}`)
                .fontSize(40)
                .fontWeight(FontWeight.Bold)
                .fontColor('#ff4da6')
                .margin({ bottom: 16 })
            } else {
              Text('贪吃蛇')
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#00d4ff')
                .margin({ bottom: 16 })
            }

            Button(this.gameState === 'OVER' ? '再来一局' : '开始游戏')
              .width(140)
              .height(44)
              .fontSize(16)
              .fontColor('#ffffff')
              .backgroundColor('#00d4ff')
              .borderRadius(8)
              .onClick(() => this.startGame())
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .backgroundColor('rgba(10, 10, 20, 0.88)')
        }
      }
      .width(this.canvasWidth)
      .height(this.canvasHeight)
      .border({ width: 2, color: '#00d4ff' })
      .margin({ top: 8 })

      Row() {
        if (this.gameState === 'PLAYING') {
          Button('暂停')
            .width(80)
            .height(36)
            .fontSize(14)
            .fontColor('#ffffff')
            .backgroundColor('#ff9800')
            .borderRadius(8)
            .onClick(() => this.pauseGame())
        } else if (this.gameState === 'PAUSED') {
          Button('继续')
            .width(80)
            .height(36)
            .fontSize(14)
            .fontColor('#ffffff')
            .backgroundColor('#4CAF50')
            .borderRadius(8)
            .onClick(() => this.startGame())
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ top: 12 })

      Column() {
        Button('▲')
          .width(52)
          .height(52)
          .fontSize(20)
          .backgroundColor('rgba(0, 212, 255, 0.1)')
          .fontColor('#00d4ff')
          .border({ width: 1, color: '#00d4ff' })
          .borderRadius(6)
          .onClick(() => this.changeDirection('UP'))

        Row() {
          Button('◄')
            .width(52)
            .height(52)
            .fontSize(20)
            .backgroundColor('rgba(0, 212, 255, 0.1)')
            .fontColor('#00d4ff')
            .border({ width: 1, color: '#00d4ff' })
            .borderRadius(6)
            .onClick(() => this.changeDirection('LEFT'))

          Blank().width(52)

          Button('►')
            .width(52)
            .height(52)
            .fontSize(20)
            .backgroundColor('rgba(0, 212, 255, 0.1)')
            .fontColor('#00d4ff')
            .border({ width: 1, color: '#00d4ff' })
            .borderRadius(6)
            .onClick(() => this.changeDirection('RIGHT'))
        }
        .width(156)
        .margin({ top: 8, bottom: 8 })

        Button('▼')
          .width(52)
          .height(52)
          .fontSize(20)
          .backgroundColor('rgba(0, 212, 255, 0.1)')
          .fontColor('#00d4ff')
          .border({ width: 1, color: '#00d4ff' })
          .borderRadius(6)
          .onClick(() => this.changeDirection('DOWN'))
      }
      .margin({ top: 8 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0a0a14')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
