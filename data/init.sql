CREATE TYPE user_role AS ENUM ('admin', 'user','critic');

CREATE TABLE Users (
    id int primary key GENERATED ALWAYS AS IDENTITY,
    name VARCHAR(100) NOT NULL,
    mail VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL CHECK (password ~ '^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}$'),
    role user_role DEFAULT NULL
);
--добавить "рейтинг"
ALTER TABLE Users 
ADD COLUMN rating DECIMAL(3, 1) DEFAULT 0 NOT NULL;


CREATE TABLE Movies (
    id int primary key GENERATED ALWAYS AS IDENTITY,
    title VARCHAR(50) NOT NULL,
    description VARCHAR(255),
    genres VARCHAR(25)[],
    rating DECIMAL(3, 1) CHECK (rating BETWEEN 0 AND 10) DEFAULT 0,
    review_count INT DEFAULT 0
);

CREATE TABLE Critic_reviews (
    id int primary key GENERATED ALWAYS AS IDENTITY,
    title VARCHAR(50) NOT NULL,
    text VARCHAR(255),
    rating DECIMAL(3, 1) NOT NULL CHECK (rating BETWEEN 0 AND 10) DEFAULT 0,
    movie_id int NOT NULL REFERENCES Movies(id) ON DELETE CASCADE,
    user_id int NOT NULL REFERENCES Users(id) ON DELETE CASCADE
);

CREATE TABLE User_reviews (
    id int primary key GENERATED ALWAYS AS IDENTITY,
    text VARCHAR(255),
    rating DECIMAL(3, 1) NOT NULL CHECK (rating BETWEEN 0 AND 10) DEFAULT 0,
    movie_id int NOT NULL REFERENCES Movies(id) ON DELETE CASCADE,
    user_id int NOT NULL REFERENCES Users(id) ON DELETE CASCADE
);

ALTER TABLE User_reviews 
ADD COLUMN created_at TIMESTAMP NOT NULL DEFAULT NOW();

CREATE TABLE Articles (
    id int primary key GENERATED ALWAYS AS IDENTITY,
    title VARCHAR(50) NOT NULL,
    text VARCHAR(255),
    tags VARCHAR(25)[],
    user_id int NOT NULL REFERENCES Users(id) ON DELETE CASCADE
);

-- Представления
-- Отчет о фильмах с информацией о рейтинге, количестве просмотров, жанрах и количестве отзывов.
CREATE OR REPLACE VIEW movie_report AS
SELECT 
    m.title, 
    COALESCE(m.rating, 0) AS rating, 
    COALESCE(m.genres, '{}') AS genres,
    COALESCE(COUNT(cr.id), 0) AS review_count
FROM Movies m
LEFT JOIN User_reviews cr ON m.id = cr.movie_id
GROUP BY m.id, m.title, m.rating, m.genres
ORDER BY rating DESC; -- Сортировка по рейтингу фильма

-- Отчет о зарегистрированных пользователях.
CREATE OR REPLACE VIEW user_report AS
SELECT 
    u.id AS user_id, 
    u.name, 
    u.mail, 
    u.role, 
    u.rating, 
    COALESCE(COUNT(ur.id), 0) AS review_count,  -- Количество пользовательских отзывов
    COALESCE(COUNT(cr.id), 0) AS critic_review_count,  -- Количество критических отзывов
    COALESCE(COUNT(a.id), 0) AS article_count  -- Количество статей
FROM Users u
LEFT JOIN User_reviews ur ON u.id = ur.user_id
LEFT JOIN Critic_reviews cr ON u.id = cr.user_id
LEFT JOIN Articles a ON u.id = a.user_id
GROUP BY u.id, u.name, u.mail, u.role, u.rating
ORDER BY u.rating DESC;

-- отзывы.
CREATE OR REPLACE VIEW filtered_reviews AS
SELECT 
    r.text AS review_text, 
    r.rating AS stars, 
    m.title AS movie_title, 
    u.name AS user_name
FROM User_reviews r
JOIN Movies m ON r.movie_id = m.id
JOIN Users u ON r.user_id = u.id

UNION ALL

SELECT 
    cr.text AS review_text, 
    cr.rating AS stars, 
    m.title AS movie_title, 
    u.name AS user_name
FROM Critic_reviews cr
JOIN Movies m ON cr.movie_id = m.id
JOIN Users u ON cr.user_id = u.id

ORDER BY stars DESC, movie_title ASC;  -- Сортировка по убыванию рейтинга и по названию фильма


-- Функции
-- Средний рейтинг от критиков
CREATE OR REPLACE FUNCTION get_avg_critic_rating(p_movie_id INT)
RETURNS DECIMAL(3, 1)
LANGUAGE plpgsql
AS $$
DECLARE
    avg_critic_rating DECIMAL(3, 1);
BEGIN
    SELECT COALESCE(AVG(rating), 0) INTO avg_critic_rating
    FROM Critic_reviews
    WHERE Critic_reviews.movie_id = p_movie_id;
    RETURN avg_critic_rating;
END;
$$;
-- Средний рейтинг от пользователей
CREATE OR REPLACE FUNCTION get_avg_user_rating(p_movie_id INT)
RETURNS DECIMAL(3, 1)
LANGUAGE plpgsql
AS $$
DECLARE
    avg_user_rating DECIMAL(3, 1);
BEGIN
    SELECT COALESCE(AVG(rating), 0) INTO avg_user_rating
    FROM User_reviews
    WHERE User_reviews.movie_id = p_movie_id;
    RETURN avg_user_rating;
END;
$$;
-- Информация о фильмах
CREATE OR REPLACE FUNCTION get_movie_info(p_movie_id INT)
RETURNS TABLE(
    title VARCHAR,
    description VARCHAR,
    genres VARCHAR[],
    avg_rating DECIMAL(3, 1),
    review_count INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT m.title, m.description, m.genres,
           (get_avg_critic_rating(p_movie_id) + get_avg_user_rating(p_movie_id)) / 2 AS avg_rating,
           m.review_count
    FROM Movies m
    WHERE m.id = p_movie_id;
END;
$$;

-- Сохранение фильмов в дб.
CREATE OR REPLACE PROCEDURE save_movie(
    p_title VARCHAR(50),
    p_description VARCHAR(255),
    p_genres VARCHAR(25)[],
    p_rating DECIMAL(3, 1) DEFAULT 0,
    p_review_count INT DEFAULT 0
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Проверяем, существует ли фильм с таким названием и такими жанрами
    IF EXISTS (
        SELECT 1 
        FROM Movies 
        WHERE title = p_title 
          AND genres = p_genres
    ) THEN
        RAISE NOTICE 'Фильм с таким названием и жанрами уже существует';
        RETURN;
    END IF;

    -- Если такого фильма нет, вставляем новый фильм
    INSERT INTO Movies (title, description, genres, rating, review_count)
    VALUES (p_title, p_description, p_genres, p_rating, p_review_count);
END;
$$;



-- Обновление рейтинга (се на триггерах)
CREATE OR REPLACE FUNCTION update_user_rating(p_user_id INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
DECLARE
    review_count INT;
    article_count INT;
    critic_review_count INT;
    new_rating DECIMAL(3, 1);
    user_role user_role;
BEGIN
    SELECT role INTO user_role FROM Users WHERE id = p_user_id;
    SELECT COUNT(id) INTO review_count FROM User_reviews WHERE user_id = p_user_id;
    SELECT COUNT(id) INTO critic_review_count FROM Critic_reviews WHERE user_id = p_user_id;
    SELECT COUNT(id) INTO article_count FROM Articles WHERE user_id = p_user_id;
    IF user_role = 'critic'::user_role THEN
        new_rating := review_count * 1.5 + article_count * 2.0 + critic_review_count * 3.0;
    ELSE
        new_rating := review_count * 1.5 + article_count * 2.0;
    END IF;
    UPDATE Users
    SET rating = new_rating
    WHERE id = p_user_id;
END;
$$;

-- Процедуры
-- Добавить отзыв критика.
CREATE OR REPLACE PROCEDURE add_critic_review(
    p_movie_id INT,
    p_user_id INT,
    p_review_title VARCHAR,
    p_review_text TEXT,
    p_review_rating NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_role user_role;
BEGIN
    SELECT role INTO user_role 
    FROM Users 
    WHERE id = p_user_id;
    IF NOT FOUND THEN
        RAISE NOTICE 'Пользователь с ID % не существует', p_user_id;
        RETURN;
    END IF;
    IF user_role <> 'critic'::user_role THEN
        RAISE NOTICE 'Только пользователь с ролью критика может оставлять критические отзывы';
        RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Movies WHERE id = p_movie_id) THEN
        RAISE NOTICE 'Фильм с ID % не существует', p_movie_id;
        RETURN;
    END IF;
    IF p_review_rating < 0 OR p_review_rating > 10 THEN
        RAISE NOTICE 'Некорректное значение рейтинга: %', p_review_rating;
        RETURN;
    END IF;
    INSERT INTO Critic_reviews (movie_id, user_id, title, text, rating)
    VALUES (p_movie_id, p_user_id, p_review_title, p_review_text, p_review_rating);
    UPDATE Movies
    SET rating = (SELECT AVG(rating) FROM Critic_reviews WHERE movie_id = p_movie_id)
    WHERE id = p_movie_id;
    RAISE NOTICE 'Отзыв критика добавлен для фильма ID % пользователем ID %', p_movie_id, p_user_id;
END;
$$;

-- Удаление критик отзыва.
CREATE OR REPLACE PROCEDURE delete_critic_review(
    review_id INT,
    p_user_id INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    user_role user_role;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Critic_reviews WHERE id = review_id) THEN
        RAISE EXCEPTION USING MESSAGE = format('Критический отзыв с ID % не существует', review_id);
    END IF;
    SELECT role INTO user_role FROM Users WHERE id = p_user_id;
    IF user_role = 'critic'::user_role THEN
        DELETE FROM Critic_reviews WHERE id = review_id;
        RAISE NOTICE 'Критический отзыв с ID % удалён критиком %', review_id, p_user_id;
    ELSE
        DELETE FROM Critic_reviews WHERE id = review_id AND user_id = p_user_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION USING MESSAGE = format('Критический отзыв с ID % не принадлежит пользователю %', review_id, p_user_id);
        END IF;
        RAISE NOTICE 'Критический отзыв с ID % удалён пользователем %', review_id, p_user_id;
    END IF;
END;
$$;

-- Удаление отзыва.
CREATE OR REPLACE PROCEDURE delete_user_review(review_id INT, p_user_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    user_role user_role;
    review_created_at TIMESTAMP;
BEGIN
    -- Проверяем существование отзыва
    IF NOT EXISTS (SELECT 1 FROM User_reviews WHERE id = review_id) THEN
        RAISE EXCEPTION 'Отзыв с ID % не существует', review_id;
    END IF;

    -- Получаем время создания отзыва
    SELECT created_at INTO review_created_at FROM User_reviews WHERE id = review_id;

    -- Проверяем, прошло ли больше 20 часов
    IF review_created_at < NOW() - INTERVAL '20 hours' THEN
        RAISE EXCEPTION 'Удаление отзыва с ID % невозможно, так как прошло более 20 часов с момента создания', review_id;
    END IF;

    -- Получаем роль пользователя
    SELECT role INTO user_role FROM Users WHERE id = p_user_id;

    -- Проверка роли и удаление отзыва
    IF user_role = 'admin'::user_role THEN
        DELETE FROM User_reviews WHERE id = review_id;
        RAISE NOTICE 'Отзыв с ID % удален администратором %', review_id, p_user_id;
    ELSE
        DELETE FROM User_reviews WHERE id = review_id AND user_id = p_user_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Отзыв с ID % не принадлежит пользователю с ID %', review_id, p_user_id;
        END IF;
        RAISE NOTICE 'Отзыв с ID % удален пользователем %', review_id, p_user_id;
    END IF;
END;
$$;


--Удаление статьи
CREATE OR REPLACE PROCEDURE delete_article(article_id INT, p_user_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Articles WHERE id = article_id) THEN
        RAISE EXCEPTION 'Статья с ID % не существует', article_id;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Articles WHERE id = article_id AND user_id = p_user_id) THEN
        RAISE EXCEPTION 'Статья с ID % не принадлежит пользователю %', article_id, p_user_id;
    END IF;
    DELETE FROM Articles WHERE id = article_id AND user_id = p_user_id;
    RAISE NOTICE 'Статья с идентификатором % удалена пользователем %', article_id, p_user_id;
END;
$$;

-- Статистика пользователя
CREATE OR REPLACE PROCEDURE get_user_statistics(p_user_id INT, OUT review_count INT, OUT article_count INT)
LANGUAGE plpgsql
AS $$
BEGIN
    SELECT COUNT(id) INTO review_count FROM User_reviews WHERE user_id = p_user_id;
    SELECT COUNT(id) INTO article_count FROM Articles WHERE user_id = p_user_id;
END;
$$;

-- Пользовательский отзыв.
CREATE OR REPLACE PROCEDURE add_user_review(
    p_movie_id INT, 
    p_user_id INT, 
    p_review_text TEXT, 
    p_review_rating NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Users WHERE id = p_user_id) THEN
        RAISE NOTICE 'Пользователь с ID % не найден', p_user_id;
        RETURN;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM Movies WHERE id = p_movie_id) THEN
        RAISE NOTICE 'Фильм с ID % не найден', p_movie_id;
        RETURN;
    END IF;
    IF p_review_rating < 0 OR p_review_rating > 10 THEN
        RAISE NOTICE 'Некорректный рейтинг: %. Рейтинг должен быть в диапазоне от 0 до 10.', p_review_rating;
        RETURN;
    END IF;
    INSERT INTO User_reviews (movie_id, user_id, text, rating, created_at)
    VALUES (p_movie_id, p_user_id, p_review_text, p_review_rating, NOW());
    UPDATE Movies
    SET 
        review_count = review_count + 1,
        rating = (SELECT AVG(rating) FROM User_reviews WHERE movie_id = p_movie_id)
    WHERE id = p_movie_id;
    RAISE NOTICE 'Пользовательский отзыв успешно добавлен для фильма ID % пользователем ID %', p_movie_id, p_user_id;
END;
$$;

-- Добавление статьи.
CREATE OR REPLACE PROCEDURE add_article(
    p_user_id INT, 
    p_article_title VARCHAR, 
    p_article_text VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Users WHERE id = p_user_id) THEN
        RAISE NOTICE 'Пользователь с ID % не найден', p_user_id;
        RETURN;
    END IF;
    IF LENGTH(p_article_title) < 5 THEN
        RAISE NOTICE 'Заголовок слишком короткий. Минимальная длина: 5 символов.';
        RETURN;
    END IF;
    IF LENGTH(p_article_title) > 255 THEN
        RAISE NOTICE 'Заголовок слишком длинный. Максимальная длина: 255 символов.';
        RETURN;
    END IF;
    IF LENGTH(p_article_text) < 20 THEN
        RAISE NOTICE 'Текст статьи слишком короткий. Минимальная длина: 20 символов.';
        RETURN;
    END IF;
    INSERT INTO Articles (title, text, user_id)
    VALUES (p_article_title, p_article_text, p_user_id);
    RAISE NOTICE 'Статья "%", добавлена пользователем ID %', p_article_title, p_user_id;
END;
$$;

-- Триггеры, 1 отзыв на фильм.
CREATE OR REPLACE FUNCTION ensure_single_review()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM User_reviews
        WHERE user_id = NEW.user_id AND movie_id = NEW.movie_id
    ) THEN
        RAISE EXCEPTION 'Пользователь может оставить только один отзыв на фильм';
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER single_review_per_movie
BEFORE INSERT ON User_reviews
FOR EACH ROW
EXECUTE FUNCTION ensure_single_review();

-- Обновляем рейтинг по отзывам.
CREATE OR REPLACE FUNCTION trg_update_rating_after_review()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM update_user_rating(NEW.user_id);
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM update_user_rating(OLD.user_id);
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM update_user_rating(NEW.user_id);
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_update_rating_reviews
AFTER INSERT OR DELETE OR UPDATE ON User_reviews
FOR EACH ROW
EXECUTE FUNCTION trg_update_rating_after_review();

-- Для статей
CREATE OR REPLACE FUNCTION trg_update_rating_after_article()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM update_user_rating(NEW.user_id);
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM update_user_rating(OLD.user_id);
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM update_user_rating(NEW.user_id);
    END IF;

    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_update_rating_articles
AFTER INSERT OR DELETE OR UPDATE ON Articles
FOR EACH ROW
EXECUTE FUNCTION trg_update_rating_after_article();

-- Для критик отзыва
CREATE OR REPLACE FUNCTION trg_update_rating_after_critic_review()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        PERFORM update_user_rating(NEW.user_id);
    ELSIF TG_OP = 'DELETE' THEN
        PERFORM update_user_rating(OLD.user_id);
    ELSIF TG_OP = 'UPDATE' THEN
        PERFORM update_user_rating(NEW.user_id);
    END IF;
    RETURN NULL;
END;
$$;

CREATE TRIGGER trg_update_rating_critic_reviews
AFTER INSERT OR DELETE OR UPDATE ON Critic_reviews
FOR EACH ROW
EXECUTE FUNCTION trg_update_rating_after_critic_review();


INSERT INTO Movies (title, description, genres, rating, review_count)
VALUES 
('Темный рыцарь', 'Супергеройский фильм о том, как Бэтмен пытается остановить Джокера', '{"Преступление", "Драма"}', 0.0, 0),
('Начало', 'Научно-фантастический триллер о снах внутри снов', '{"Действие", "Приключение", "Научная фантастика"}', 0.0, 0),
('Интерстеллар', 'Фильм об исследовании космоса и спасении человечества', '{"Приключение", "Драма", "Научная фантастика"}', 0.0, 0),
('Крестный отец', 'Криминальная драма о мафии', '{"Преступление", "Драма"}', 0.0, 0),
('Побег из Шоушенка', 'История о человеке, ошибочно заключенном в тюрьму', '{"Драма"}', 0.0, 0);
