
-- =====================================================
-- PROJET : E-LEARNING PLATFORM
-- SGBD   : PostgreSQL
-- VERSION: 1.0
-- =====================================================

-- =====================================================
-- 1. TABLE USERS
-- =====================================================

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    full_name VARCHAR(100) NOT NULL,

    email VARCHAR(150) NOT NULL,

    password_hash VARCHAR(255) NOT NULL,

    role VARCHAR(20) NOT NULL DEFAULT 'student'
        CHECK (role IN ('student', 'teacher', 'admin')),

    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_users_email
ON users (LOWER(email));


-- =====================================================
-- 2. TABLE COURSES
-- =====================================================

CREATE TABLE courses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    teacher_id BIGINT NOT NULL,

    title VARCHAR(150) NOT NULL,

    description TEXT,

    image_path TEXT,

    status VARCHAR(20) NOT NULL DEFAULT 'draft'
        CHECK (status IN ('draft', 'published', 'archived')),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_course_teacher
        FOREIGN KEY (teacher_id)
        REFERENCES users(id)
        ON DELETE RESTRICT
);


-- =====================================================
-- 3. TABLE ENROLLMENTS
-- =====================================================

CREATE TABLE enrollments (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    student_id BIGINT NOT NULL,

    course_id BIGINT NOT NULL,

    enrolled_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    status VARCHAR(20) NOT NULL DEFAULT 'active'
        CHECK (status IN ('active', 'completed', 'cancelled')),

    CONSTRAINT fk_enrollment_student
        FOREIGN KEY (student_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_enrollment_course
        FOREIGN KEY (course_id)
        REFERENCES courses(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_student_course
        UNIQUE (student_id, course_id)
);


-- =====================================================
-- 4. TABLE LESSONS
-- =====================================================

CREATE TABLE lessons (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    course_id BIGINT NOT NULL,

    title VARCHAR(150) NOT NULL,

    content TEXT,

    order_number INTEGER NOT NULL CHECK (order_number > 0),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_lesson_course
        FOREIGN KEY (course_id)
        REFERENCES courses(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_lesson_order
        UNIQUE (course_id, order_number)
);


-- =====================================================
-- 5. TABLE DOCUMENTS
-- =====================================================

CREATE TABLE documents (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    lesson_id BIGINT NOT NULL,

    file_name VARCHAR(255) NOT NULL,

    storage_path TEXT NOT NULL,

    file_size BIGINT CHECK (file_size IS NULL OR file_size >= 0),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_document_lesson
        FOREIGN KEY (lesson_id)
        REFERENCES lessons(id)
        ON DELETE CASCADE
);


-- =====================================================
-- 6. TABLE VIDEOS
-- =====================================================

CREATE TABLE videos (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    lesson_id BIGINT NOT NULL,

    title VARCHAR(150) NOT NULL,

    storage_path TEXT,

    video_url TEXT,

    duration_seconds INTEGER
        CHECK (duration_seconds IS NULL OR duration_seconds >= 0),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_video_lesson
        FOREIGN KEY (lesson_id)
        REFERENCES lessons(id)
        ON DELETE CASCADE,

    CONSTRAINT check_video_source
        CHECK (
            (storage_path IS NOT NULL AND video_url IS NULL)
            OR
            (storage_path IS NULL AND video_url IS NOT NULL)
        )
);


-- =====================================================
-- 7. TABLE QUIZZES
-- =====================================================

CREATE TABLE quizzes (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    course_id BIGINT NOT NULL,

    title VARCHAR(150) NOT NULL,

    description TEXT,

    duration_minutes INTEGER
        CHECK (duration_minutes IS NULL OR duration_minutes > 0),

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_quiz_course
        FOREIGN KEY (course_id)
        REFERENCES courses(id)
        ON DELETE CASCADE
);


-- =====================================================
-- 8. TABLE QUESTIONS
-- =====================================================

CREATE TABLE questions (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    quiz_id BIGINT NOT NULL,

    question_text TEXT NOT NULL,

    order_number INTEGER NOT NULL CHECK (order_number > 0),

    CONSTRAINT fk_question_quiz
        FOREIGN KEY (quiz_id)
        REFERENCES quizzes(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_question_order
        UNIQUE (quiz_id, order_number)
);


-- =====================================================
-- 9. TABLE ANSWERS
-- =====================================================

CREATE TABLE answers (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    question_id BIGINT NOT NULL,

    answer_text TEXT NOT NULL,

    is_correct BOOLEAN NOT NULL DEFAULT FALSE,

    order_number INTEGER NOT NULL CHECK (order_number > 0),

    CONSTRAINT fk_answer_question
        FOREIGN KEY (question_id)
        REFERENCES questions(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_answer_order
        UNIQUE (question_id, order_number),

    CONSTRAINT unique_answer_question_pair
        UNIQUE (id, question_id)
);


-- =====================================================
-- 10. TABLE QUIZ_ATTEMPTS
-- =====================================================

CREATE TABLE quiz_attempts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    student_id BIGINT NOT NULL,

    quiz_id BIGINT NOT NULL,

    score NUMERIC(5,2)
        CHECK (score IS NULL OR score BETWEEN 0 AND 100),

    status VARCHAR(20) NOT NULL DEFAULT 'in_progress'
        CHECK (status IN ('in_progress', 'submitted')),

    started_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    submitted_at TIMESTAMP,

    CONSTRAINT fk_attempt_student
        FOREIGN KEY (student_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_attempt_quiz
        FOREIGN KEY (quiz_id)
        REFERENCES quizzes(id)
        ON DELETE CASCADE,

    CONSTRAINT check_attempt_dates
        CHECK (
            submitted_at IS NULL
            OR submitted_at >= started_at
        ),

    CONSTRAINT check_attempt_status
        CHECK (
            (status = 'in_progress' AND submitted_at IS NULL)
            OR
            (status = 'submitted' AND submitted_at IS NOT NULL)
        )
);


-- =====================================================
-- 11. TABLE QUIZ_RESPONSES
-- =====================================================

CREATE TABLE quiz_responses (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    attempt_id BIGINT NOT NULL,

    question_id BIGINT NOT NULL,

    answer_id BIGINT NOT NULL,

    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_response_attempt
        FOREIGN KEY (attempt_id)
        REFERENCES quiz_attempts(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_response_question
        FOREIGN KEY (question_id)
        REFERENCES questions(id)
        ON DELETE CASCADE,

    CONSTRAINT fk_response_answer_question
        FOREIGN KEY (answer_id, question_id)
        REFERENCES answers(id, question_id)
        ON DELETE CASCADE,

    CONSTRAINT unique_attempt_question
        UNIQUE (attempt_id, question_id)
);


-- =====================================================
-- 12. TABLE LESSON_PROGRESS
-- =====================================================

CREATE TABLE lesson_progress (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    student_id BIGINT NOT NULL,

    lesson_id BIGINT NOT NULL,

    is_completed BOOLEAN NOT NULL DEFAULT FALSE,

    completed_at TIMESTAMP,

    CONSTRAINT fk_progress_student
        FOREIGN KEY (student_id)
        REFERENCES users(id)
        ON DELETE RESTRICT,

    CONSTRAINT fk_progress_lesson
        FOREIGN KEY (lesson_id)
        REFERENCES lessons(id)
        ON DELETE CASCADE,

    CONSTRAINT unique_student_lesson
        UNIQUE (student_id, lesson_id),

    CONSTRAINT check_progress_date
        CHECK (
            (is_completed = FALSE AND completed_at IS NULL)
            OR
            (is_completed = TRUE AND completed_at IS NOT NULL)
        )
);


-- =====================================================
-- 13. INDEX POUR AMELIORER LES PERFORMANCES
-- =====================================================

CREATE INDEX idx_courses_teacher
ON courses(teacher_id);

CREATE INDEX idx_courses_status
ON courses(status);

CREATE INDEX idx_enrollments_student
ON enrollments(student_id);

CREATE INDEX idx_enrollments_course
ON enrollments(course_id);

CREATE INDEX idx_lessons_course
ON lessons(course_id);

CREATE INDEX idx_documents_lesson
ON documents(lesson_id);

CREATE INDEX idx_videos_lesson
ON videos(lesson_id);

CREATE INDEX idx_quizzes_course
ON quizzes(course_id);

CREATE INDEX idx_questions_quiz
ON questions(quiz_id);

CREATE INDEX idx_answers_question
ON answers(question_id);

CREATE INDEX idx_attempts_student
ON quiz_attempts(student_id);

CREATE INDEX idx_attempts_quiz
ON quiz_attempts(quiz_id);

CREATE INDEX idx_responses_attempt
ON quiz_responses(attempt_id);

CREATE INDEX idx_progress_student
ON lesson_progress(student_id);


-- =====================================================
-- 14. FONCTION DE MISE A JOUR AUTOMATIQUE
-- =====================================================

CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- =====================================================
-- 15. TRIGGERS
-- =====================================================

CREATE TRIGGER trg_users_updated_at
BEFORE UPDATE ON users
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_courses_updated_at
BEFORE UPDATE ON courses
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_lessons_updated_at
BEFORE UPDATE ON lessons
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER trg_quizzes_updated_at
BEFORE UPDATE ON quizzes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at();


-- =====================================================
-- FIN DU SCRIPT
-- =====================================================
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
--test----
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_type = 'BASE TABLE'
ORDER BY table_name;
--test test tes t------------------------
-------------------------------------
--------------------------------------
SELECT
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS referenced_table,
    ccu.column_name AS referenced_column
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.constraint_schema = kcu.constraint_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.constraint_schema = tc.constraint_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
AND tc.table_schema = 'public'
ORDER BY tc.table_name;
