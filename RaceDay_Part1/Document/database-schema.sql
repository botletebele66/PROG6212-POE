-- =====================================================
-- RaceDay Database Setup Script
-- =====================================================
-- Full-stack event management system for South Africa's
-- road running, walking, and cycling community.
--
-- This script creates the complete database schema for
-- RaceDay, including all tables, primary/foreign keys,
-- constraints, and sample seed data.
--
-- Author: Botshelo
-- Course: Software Development (Rosebank College)
-- Part 1: System Planning & Database
-- =====================================================

-- =====================================================
-- (OPTIONAL) DROP EXISTING TABLES
-- Uncomment if re-running this script on an existing DB.
-- Dropped in reverse dependency order (children first).
-- =====================================================
-- IF OBJECT_ID('Result', 'U') IS NOT NULL DROP TABLE Result;
-- IF OBJECT_ID('Enrolment', 'U') IS NOT NULL DROP TABLE Enrolment;
-- IF OBJECT_ID('EventCategory', 'U') IS NOT NULL DROP TABLE EventCategory;
-- IF OBJECT_ID('Event', 'U') IS NOT NULL DROP TABLE Event;
-- IF OBJECT_ID('Participant', 'U') IS NOT NULL DROP TABLE Participant;
-- IF OBJECT_ID('Organiser', 'U') IS NOT NULL DROP TABLE Organiser;
-- IF OBJECT_ID('[User]', 'U') IS NOT NULL DROP TABLE [User];

-- =====================================================
-- CREATE TABLES
-- =====================================================

-- 1. User Table (Base table for both Organisers and Participants)
CREATE TABLE [User] (
    UserID          INT IDENTITY(1,1) PRIMARY KEY,
    Email           NVARCHAR(255) NOT NULL UNIQUE,
    Password        NVARCHAR(255) NOT NULL,               -- store a hashed password, never plain text
    FirstName       NVARCHAR(100) NOT NULL,
    LastName        NVARCHAR(100) NOT NULL,
    UserRole        NVARCHAR(50)  NOT NULL
                        CHECK (UserRole IN ('Organiser', 'Participant')),
    CreatedDate     DATETIME NOT NULL DEFAULT GETDATE()
);

-- 2. Organiser Table (1-to-1 extension of User where UserRole = 'Organiser')
CREATE TABLE Organiser (
    OrganiserID         INT IDENTITY(1,1) PRIMARY KEY,
    UserID              INT NOT NULL UNIQUE,               -- UNIQUE enforces 1-to-1 with User
    CompanyName         NVARCHAR(255) NOT NULL,
    PhoneNumber         NVARCHAR(20),
    RegistrationNumber  NVARCHAR(50) UNIQUE,
    CONSTRAINT FK_Organiser_User FOREIGN KEY (UserID)
        REFERENCES [User](UserID) ON DELETE CASCADE
);

-- 3. Participant Table (1-to-1 extension of User where UserRole = 'Participant')
CREATE TABLE Participant (
    ParticipantID       INT IDENTITY(1,1) PRIMARY KEY,
    UserID              INT NOT NULL UNIQUE,
    DateOfBirth         DATE,
    PhoneNumber         NVARCHAR(20),
    EmergencyContact    NVARCHAR(255),
    CONSTRAINT FK_Participant_User FOREIGN KEY (UserID)
        REFERENCES [User](UserID) ON DELETE CASCADE
);

-- 4. Event Table (created and owned by an Organiser)
CREATE TABLE Event (
    EventID          INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserID       INT NOT NULL,
    EventName         NVARCHAR(255) NOT NULL,
    EventDate         DATETIME NOT NULL,
    Location          NVARCHAR(255) NOT NULL,
    EventType         NVARCHAR(50) NOT NULL
                          CHECK (EventType IN ('Running', 'Walking', 'Cycling')),
    Description       NVARCHAR(MAX),
    MaxParticipants   INT CHECK (MaxParticipants > 0),
    CreatedDate       DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserID)
        REFERENCES Organiser(OrganiserID) ON DELETE CASCADE
);

-- 5. EventCategory Table (an Event has many distance/fee categories)
CREATE TABLE EventCategory (
    CategoryID       INT IDENTITY(1,1) PRIMARY KEY,
    EventID          INT NOT NULL,
    CategoryName     NVARCHAR(100) NOT NULL,
    Distance         DECIMAL(10,2) NOT NULL CHECK (Distance > 0),  -- in km
    EntryFee         DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (EntryFee >= 0),
    AgeRestriction   INT NULL,                                     -- minimum age, NULL = no restriction
    CONSTRAINT FK_EventCategory_Event FOREIGN KEY (EventID)
        REFERENCES Event(EventID) ON DELETE CASCADE
);

-- 6. Enrolment Table (junction table: Participant <-> EventCategory)
CREATE TABLE Enrolment (
    EnrolmentID      INT IDENTITY(1,1) PRIMARY KEY,
    ParticipantID    INT NOT NULL,
    CategoryID       INT NOT NULL,
    EnrolmentDate    DATETIME NOT NULL DEFAULT GETDATE(),
    Status           NVARCHAR(50) NOT NULL DEFAULT 'Registered'
                         CHECK (Status IN ('Registered', 'Started', 'Completed', 'Withdrawn')),
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (ParticipantID)
        REFERENCES Participant(ParticipantID) ON DELETE CASCADE,
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (CategoryID)
        REFERENCES EventCategory(CategoryID) ON DELETE CASCADE,
    -- A participant should not be able to enrol in the same category twice
    CONSTRAINT UQ_Enrolment_Participant_Category UNIQUE (ParticipantID, CategoryID)
);

-- 7. Result Table (one result per enrolment, once the race is completed)
CREATE TABLE Result (
    ResultID         INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentID      INT NOT NULL UNIQUE,      -- UNIQUE enforces 1-to-1 with Enrolment
    TimeCompleted    INT CHECK (TimeCompleted >= 0),   -- finish time, in seconds
    PlacementRank    INT CHECK (PlacementRank > 0),
    DateCompleted    DATETIME NOT NULL DEFAULT GETDATE(),
    -- ON DELETE CASCADE deliberately NOT used here: cascading three levels deep
    -- (Enrolment -> Participant/Category -> ...) from Result would create multiple
    -- cascade paths back to the same tables, which SQL Server rejects. NO ACTION
    -- means a Result must be deleted explicitly before its Enrolment can be removed.
    CONSTRAINT FK_Result_Enrolment FOREIGN KEY (EnrolmentID)
        REFERENCES Enrolment(EnrolmentID) ON DELETE NO ACTION
);

-- =====================================================
-- INDEXES (for common lookups / foreign keys)
-- =====================================================
CREATE INDEX IX_Event_OrganiserID ON Event(OrganiserID);
CREATE INDEX IX_EventCategory_EventID ON EventCategory(EventID);
CREATE INDEX IX_Enrolment_ParticipantID ON Enrolment(ParticipantID);
CREATE INDEX IX_Enrolment_CategoryID ON Enrolment(CategoryID);

-- =====================================================
-- INSERT SEED DATA
-- =====================================================

-- ---- Users: Organisers ----
INSERT INTO [User] (Email, Password, FirstName, LastName, UserRole)
VALUES
    ('org1@raceday.co.za', 'hashed_password_1', 'John', 'Smith', 'Organiser'),
    ('org2@raceday.co.za', 'hashed_password_2', 'Sarah', 'Johnson', 'Organiser');

-- ---- Organisers (UserID 1 -> John, UserID 2 -> Sarah) ----
INSERT INTO Organiser (UserID, CompanyName, PhoneNumber, RegistrationNumber)
VALUES
    (1, 'Comrades Marathon Organisers', '011-123-4567', 'REG-001'),
    (2, 'Cape Town Cycle Tours', '021-987-6543', 'REG-002');

-- ---- Users: Participants ----
INSERT INTO [User] (Email, Password, FirstName, LastName, UserRole)
VALUES
    ('participant1@example.com', 'hashed_pass_p1', 'Alice', 'Brown', 'Participant'),
    ('participant2@example.com', 'hashed_pass_p2', 'Bob', 'Davis', 'Participant');

-- ---- Participants (UserID 3 -> Alice, UserID 4 -> Bob) ----
INSERT INTO Participant (UserID, DateOfBirth, PhoneNumber, EmergencyContact)
VALUES
    (3, '1990-05-15', '082-123-4567', 'Mary Brown - 082-111-1111'),
    (4, '1985-08-22', '083-456-7890', 'Jane Davis - 083-222-2222');

-- ---- Events ----
INSERT INTO Event (OrganiserID, EventName, EventDate, Location, EventType, Description, MaxParticipants)
VALUES
    (1, 'Comrades Marathon 2026', '2026-06-14', 'Pietermaritzburg to Durban', 'Running',
     'The world''s longest and oldest ultramarathon.', 3000),
    (2, 'Cape Town Cycle Tour 2026', '2026-03-08', 'Cape Town', 'Cycling',
     'A circular timed cycle race around the Cape Peninsula.', 5000),
    (1, 'Soweto Marathon 2026', '2026-09-27', 'Soweto', 'Running',
     'Urban marathon through the streets of Soweto.', 2000);

-- ---- Event Categories ----
INSERT INTO EventCategory (EventID, CategoryName, Distance, EntryFee, AgeRestriction)
VALUES
    (1, 'Full Ultra (87km)', 87, 350.00, 18),
    (1, 'Half Marathon (21km)', 21, 200.00, 16),
    (2, '109km Route', 109, 250.00, 16),
    (2, '65km Route', 65, 200.00, 14),
    (3, 'Full Marathon (42km)', 42, 300.00, 18);

-- ---- Enrolments ----
-- ParticipantID 1 = Alice, ParticipantID 2 = Bob
INSERT INTO Enrolment (ParticipantID, CategoryID, Status)
VALUES
    (1, 1, 'Registered'),   -- Alice -> Comrades Full Ultra
    (1, 5, 'Registered'),   -- Alice -> Soweto Full Marathon
    (2, 2, 'Registered');   -- Bob   -> Comrades Half Marathon

-- ---- Results ----
INSERT INTO Result (EnrolmentID, TimeCompleted, PlacementRank)
VALUES
    (1, 36000, 150),   -- Alice's Comrades result: 10h00m00s, placed 150th
    (3, 7200, 45);      -- Bob's Half Marathon result: 2h00m00s, placed 45th

-- =====================================================
-- VERIFICATION QUERIES (run manually after executing the script)
-- =====================================================
-- SELECT * FROM [User];
-- SELECT * FROM Organiser;
-- SELECT * FROM Participant;
-- SELECT * FROM Event;
-- SELECT * FROM EventCategory;
-- SELECT * FROM Enrolment;
-- SELECT * FROM Result;

-- Example join: full enrolment picture per participant
-- SELECT u.FirstName, u.LastName, e.EventName, ec.CategoryName, en.Status, r.TimeCompleted, r.PlacementRank
-- FROM Enrolment en
-- JOIN Participant p ON en.ParticipantID = p.ParticipantID
-- JOIN [User] u ON p.UserID = u.UserID
-- JOIN EventCategory ec ON en.CategoryID = ec.CategoryID
-- JOIN Event e ON ec.EventID = e.EventID
-- LEFT JOIN Result r ON r.EnrolmentID = en.EnrolmentID;
