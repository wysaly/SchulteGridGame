-- 创建数据库
CREATE DATABASE IF NOT EXISTS schulte_grid_game;
USE schulte_grid_game;


-- 创建游戏数据表
CREATE TABLE game_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    level INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    difficulty ENUM('easy', 'medium', 'hard') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建用户表
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password VARCHAR(255) NOT NULL,
    score INT DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建古诗词表
CREATE TABLE poetry (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content VARCHAR(255)  NOT NULL,
    author VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
-- 修改数据库字符集
ALTER DATABASE schulte_grid_game CHARACTER SET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

-- 修改游戏数据表字符集
ALTER TABLE game_data CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- 修改古诗词表字符集
ALTER TABLE poetry CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- 插入古诗词游戏的测试数据
INSERT INTO game_data (level, description, difficulty) VALUES
(1, '古诗词第一关:简单的古诗', 'easy'),
(2, '古诗词第二关:稍微复杂的古诗', 'medium'),
(3, '古诗词第三关:挑战性的古诗', 'hard');

-- 插入用户测试数据
INSERT INTO users (username, password, score) VALUES
('poet1', 'password123', 100),
('poet2', 'password456', 200),
('poet3', 'password789', 150);

-- 插入古诗词示例数据
INSERT INTO poetry (title, content, author) VALUES
('春晓', '春眠不觉晓处处闻啼鸟夜来风雨声花落知多少', '孟浩然'),
('登鹳雀楼', '白日依山尽黄河入海流欲穷千里目更上一层楼', '王之涣'); 