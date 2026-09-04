-- =====================================================
-- RaceDay Database SQL
-- =====================================================
-- Full-stack event management system for South Africa's
-- road running, walking, and cycling community.
-- Author: Botshelo Letebele (ST10478568)
-- Corrected Version
-- =====================================================

-- =====================================================
-- CREATE DATABASE (if it doesn't exist) AND USE IT
-- =====================================================
USE master;
GO

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'RaceDay')
BEGIN
    CREATE DATABASE RaceDay;
END;
GO

USE RaceDay;
GO

-- =====================================================
-- DROP EXISTING TABLES (if any) – reverse dependency order
-- =====================================================
DROP TABLE IF EXISTS Result;
DROP TABLE IF EXISTS Enrolment;
DROP TABLE IF EXISTS EventCategory;
DROP TABLE IF EXISTS Event;
DROP TABLE IF EXISTS Participant;
DROP TABLE IF EXISTS Organiser;
DROP TABLE IF EXISTS Users;

-- =====================================================
-- CREATE TABLES (CORRECTED)
-- =====================================================

-- 1. Users Table (renamed from [User] to avoid reserved keyword)
CREATE TABLE Users (
    UserID          INT IDENTITY(1,1) PRIMARY KEY,
    Email           NVARCHAR(255) NOT NULL UNIQUE,
    Password        NVARCHAR(255) NOT NULL,
    FirstName       NVARCHAR(100) NOT NULL,
    LastName        NVARCHAR(100) NOT NULL,
    UserRole        NVARCHAR(50)  NOT NULL
                        CHECK (UserRole IN ('Organiser', 'Participant')),
    CreatedDate     DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedDate     DATETIME NOT NULL DEFAULT GETDATE()
);

-- 2. Organiser Table (1-to-1 extension of Users where UserRole = 'Organiser')
CREATE TABLE Organiser (
    OrganiserID         INT IDENTITY(1,1) PRIMARY KEY,
    UserID              INT NOT NULL UNIQUE,
    CompanyName         NVARCHAR(255) NOT NULL,
    PhoneNumber         NVARCHAR(20),
    RegistrationNumber  NVARCHAR(50) UNIQUE,
    UpdatedDate         DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Organiser_User FOREIGN KEY (UserID)
        REFERENCES Users(UserID) ON DELETE CASCADE
);


-- 3. Participant Table (1-to-1 extension of Users where UserRole = 'Participant')
CREATE TABLE Participant (
    ParticipantID       INT IDENTITY(1,1) PRIMARY KEY,
    UserID              INT NOT NULL UNIQUE,
    DateOfBirth         DATE,
    PhoneNumber         NVARCHAR(20),
    EmergencyContact    NVARCHAR(255),
    UpdatedDate         DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Participant_User FOREIGN KEY (UserID)
        REFERENCES Users(UserID) ON DELETE CASCADE
);

-- NOTE: No separate index needed here — UserID is UNIQUE, which SQL Server
-- already backs with a unique index automatically.

-- 4. Event Table (created and owned by an Organiser)
CREATE TABLE Event (
    EventID          INT IDENTITY(1,1) PRIMARY KEY,
    OrganiserID      INT NOT NULL,
    EventName        NVARCHAR(255) NOT NULL,
    EventDate        DATETIME NOT NULL,
    Location         NVARCHAR(255) NOT NULL,
    EventType        NVARCHAR(50) NOT NULL
                         CHECK (EventType IN ('Running', 'Walking', 'Cycling')),
    Description      NVARCHAR(MAX),
    MaxParticipants  INT CHECK (MaxParticipants > 0),
    CreatedDate      DATETIME NOT NULL DEFAULT GETDATE(),
    UpdatedDate      DATETIME NOT NULL DEFAULT GETDATE(),
    -- NOTE: A "future date only" rule is intentionally NOT enforced here as a
    -- CHECK constraint. CHECK (EventDate >= GETDATE()) is evaluated on every
    -- INSERT and UPDATE, so it would block any future update to an event once
    -- its date has passed (even unrelated column changes) and would make old
    -- seed data impossible to insert. Enforce "future event" rules at the
    -- application layer, or with an AFTER INSERT trigger if DB-level
    -- enforcement is required for creation only. This will be done by timeanddate system
    CONSTRAINT FK_Event_Organiser FOREIGN KEY (OrganiserID)
        REFERENCES Organiser(OrganiserID) ON DELETE CASCADE
);

-- 5. EventCategory Table (an Event has many distance/fee categories)
CREATE TABLE EventCategory (
    CategoryID       INT IDENTITY(1,1) PRIMARY KEY,
    EventID          INT NOT NULL,
    CategoryName     NVARCHAR(100) NOT NULL,
    Distance         DECIMAL(10,2) NOT NULL CHECK (Distance > 0),
    EntryFee         DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (EntryFee >= 0),
    AgeRestriction   INT NULL,
    UpdatedDate      DATETIME NOT NULL DEFAULT GETDATE(),
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
    UpdatedDate      DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_Enrolment_Participant FOREIGN KEY (ParticipantID)
        REFERENCES Participant(ParticipantID) ON DELETE CASCADE,
    CONSTRAINT FK_Enrolment_Category FOREIGN KEY (CategoryID)
        REFERENCES EventCategory(CategoryID) ON DELETE NO ACTION,
    CONSTRAINT UQ_Enrolment_Participant_Category UNIQUE (ParticipantID, CategoryID)
);

-- 7. Result Table (one result per enrolment, once the race is completed)
CREATE TABLE Result (
    ResultID         INT IDENTITY(1,1) PRIMARY KEY,
    EnrolmentID      INT NOT NULL UNIQUE,
    TimeCompleted    INT CHECK (TimeCompleted >= 0),
    PlacementRank    INT CHECK (PlacementRank > 0),
    DateCompleted    DATETIME NOT NULL DEFAULT GETDATE(),
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
CREATE INDEX IX_Result_DateCompleted ON Result(DateCompleted);
CREATE INDEX IX_Result_EnrolmentID ON Result(EnrolmentID);
GO

-- =====================================================
-- TRIGGERS (keep UpdatedDate columns honest on every UPDATE)
-- =====================================================
CREATE TRIGGER TR_Users_UpdatedDate ON Users
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Users SET UpdatedDate = GETDATE()
    WHERE UserID IN (SELECT UserID FROM inserted);
END;
GO

CREATE TRIGGER TR_Organiser_UpdatedDate ON Organiser
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Organiser SET UpdatedDate = GETDATE()
    WHERE OrganiserID IN (SELECT OrganiserID FROM inserted);
END;
GO

CREATE TRIGGER TR_Participant_UpdatedDate ON Participant
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Participant SET UpdatedDate = GETDATE()
    WHERE ParticipantID IN (SELECT ParticipantID FROM inserted);
END;
GO

CREATE TRIGGER TR_Event_UpdatedDate ON Event
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Event SET UpdatedDate = GETDATE()
    WHERE EventID IN (SELECT EventID FROM inserted);
END;
GO

CREATE TRIGGER TR_EventCategory_UpdatedDate ON EventCategory
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE EventCategory SET UpdatedDate = GETDATE()
    WHERE CategoryID IN (SELECT CategoryID FROM inserted);
END;
GO

CREATE TRIGGER TR_Enrolment_UpdatedDate ON Enrolment
AFTER UPDATE AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Enrolment SET UpdatedDate = GETDATE()
    WHERE EnrolmentID IN (SELECT EnrolmentID FROM inserted);
END;
GO

-- NOTE: Each trigger excludes rows where only UpdatedDate itself changed
-- would be more robust, but for a student/demo project this straightforward
-- version is intentional and easy to follow.

-- =====================================================
-- INSERT SEED DATA
-- =====================================================

-- NOTE: DBCC CHECKIDENT RESEED is not needed here — every table above was
-- just DROPped and re-CREATEd in this same script run, so each IDENTITY
-- column already starts fresh at 1.

BEGIN TRY
BEGIN TRANSACTION;

-- Declare table variables to reliably capture generated IDs (no guessing)
DECLARE @UserOut TABLE (UserID INT);
DECLARE @OrgOut TABLE (OrganiserID INT);
DECLARE @PartOut TABLE (ParticipantID INT);
DECLARE @EventOut TABLE (EventID INT);

DECLARE @UserID_Org1 INT, @UserID_Org2 INT, @UserID_Part1 INT, @UserID_Part2 INT;
DECLARE @OrganiserID_1 INT, @OrganiserID_2 INT;
DECLARE @ParticipantID_1 INT, @ParticipantID_2 INT;
DECLARE @EventID_1 INT, @EventID_2 INT, @EventID_3 INT;

-- ---- Users: Organisers ----
INSERT INTO Users (Email, Password, FirstName, LastName, UserRole)
OUTPUT inserted.UserID INTO @UserOut
VALUES
    ('org1@raceday.co.za', 'hashed_password_1', 'John', 'Smith', 'Organiser'),
    ('org2@raceday.co.za', 'hashed_password_2', 'Sarah', 'Johnson', 'Organiser');

SELECT @UserID_Org1 = MIN(UserID), @UserID_Org2 = MAX(UserID) FROM @UserOut;
DELETE FROM @UserOut;

-- ---- Users: Participants ----
INSERT INTO Users (Email, Password, FirstName, LastName, UserRole)
OUTPUT inserted.UserID INTO @UserOut
VALUES
    ('participant1@example.com', 'hashed_pass_p1', 'Alice', 'Brown', 'Participant'),
    ('participant2@example.com', 'hashed_pass_p2', 'Bob', 'Davis', 'Participant');

SELECT @UserID_Part1 = MIN(UserID), @UserID_Part2 = MAX(UserID) FROM @UserOut;

-- ---- Organisers ----
INSERT INTO Organiser (UserID, CompanyName, PhoneNumber, RegistrationNumber)
OUTPUT inserted.OrganiserID INTO @OrgOut
VALUES
    (@UserID_Org1, 'Comrades Marathon Organisers', '011-123-4567', 'REG-001'),
    (@UserID_Org2, 'Cape Town Cycle Tours', '021-987-6543', 'REG-002');

SELECT @OrganiserID_1 = MIN(OrganiserID), @OrganiserID_2 = MAX(OrganiserID) FROM @OrgOut;

-- ---- Participants ----
INSERT INTO Participant (UserID, DateOfBirth, PhoneNumber, EmergencyContact)
OUTPUT inserted.ParticipantID INTO @PartOut
VALUES
    (@UserID_Part1, '1990-05-15', '082-123-4567', 'Mary Brown - 082-111-1111'),
    (@UserID_Part2, '1985-08-22', '083-456-7890', 'Jane Davis - 083-222-2222');

SELECT @ParticipantID_1 = MIN(ParticipantID), @ParticipantID_2 = MAX(ParticipantID) FROM @PartOut;

-- ---- Events ----
-- NOTE: Dates are calculated relative to GETDATE() so this script produces
-- valid "future" events no matter when it's actually run.
INSERT INTO Event (OrganiserID, EventName, EventDate, Location, EventType, Description, MaxParticipants)
OUTPUT inserted.EventID INTO @EventOut
VALUES
    (@OrganiserID_1, 'Comrades Marathon', DATEADD(MONTH, 9, GETDATE()), 'Pietermaritzburg to Durban', 'Running',
     'The world''s longest and oldest ultramarathon.', 3000),
    (@OrganiserID_2, 'Cape Town Cycle Tour', DATEADD(MONTH, 6, GETDATE()), 'Cape Town', 'Cycling',
     'A circular timed cycle race around the Cape Peninsula.', 5000),
    (@OrganiserID_1, 'Soweto Marathon', DATEADD(YEAR, 1, GETDATE()), 'Soweto', 'Running',
     'Urban marathon through the streets of Soweto.', 2000);

SELECT @EventID_1 = MIN(EventID) FROM @EventOut;
SELECT @EventID_3 = MAX(EventID) FROM @EventOut;
SELECT @EventID_2 = EventID FROM @EventOut WHERE EventID <> @EventID_1 AND EventID <> @EventID_3;

-- ---- Event Categories ----
DECLARE @CategoryOut TABLE (CategoryID INT, CategoryName NVARCHAR(100));
DECLARE @CategoryID_FullUltra INT, @CategoryID_HalfMarathon INT, @CategoryID_FullMarathon INT;

INSERT INTO EventCategory (EventID, CategoryName, Distance, EntryFee, AgeRestriction)
OUTPUT inserted.CategoryID, inserted.CategoryName INTO @CategoryOut
VALUES
    (@EventID_1, 'Full Ultra (87km)', 87, 350.00, 18),
    (@EventID_1, 'Half Marathon (21km)', 21, 200.00, 16),
    (@EventID_2, '109km Route', 109, 250.00, 16),
    (@EventID_2, '65km Route', 65, 200.00, 14),
    (@EventID_3, 'Full Marathon (42km)', 42, 300.00, 18);

SELECT @CategoryID_FullUltra = CategoryID FROM @CategoryOut WHERE CategoryName = 'Full Ultra (87km)';
SELECT @CategoryID_HalfMarathon = CategoryID FROM @CategoryOut WHERE CategoryName = 'Half Marathon (21km)';
SELECT @CategoryID_FullMarathon = CategoryID FROM @CategoryOut WHERE CategoryName = 'Full Marathon (42km)';

-- ---- Enrolments ----
DECLARE @EnrolmentOut TABLE (EnrolmentID INT, ParticipantID INT, CategoryID INT);
DECLARE @EnrolmentID_1 INT, @EnrolmentID_3 INT;

INSERT INTO Enrolment (ParticipantID, CategoryID, Status)
OUTPUT inserted.EnrolmentID, inserted.ParticipantID, inserted.CategoryID INTO @EnrolmentOut
VALUES
    (@ParticipantID_1, @CategoryID_FullUltra, 'Registered'),
    (@ParticipantID_1, @CategoryID_FullMarathon, 'Registered'),
    (@ParticipantID_2, @CategoryID_HalfMarathon, 'Registered');

SELECT @EnrolmentID_1 = EnrolmentID FROM @EnrolmentOut
    WHERE ParticipantID = @ParticipantID_1 AND CategoryID = @CategoryID_FullUltra;
SELECT @EnrolmentID_3 = EnrolmentID FROM @EnrolmentOut
    WHERE ParticipantID = @ParticipantID_2 AND CategoryID = @CategoryID_HalfMarathon;

-- ---- Results (only for completed enrolments) ----
-- NOTE: These two results are illustrative "already completed" races, so a
-- relative past date is used regardless of when the Event rows above (which
-- are always in the future) are dated.
INSERT INTO Result (EnrolmentID, TimeCompleted, PlacementRank, DateCompleted)
VALUES
    (@EnrolmentID_1, 36000, 150, DATEADD(MONTH, -3, GETDATE())),
    (@EnrolmentID_3, 7200, 45, DATEADD(MONTH, -3, GETDATE()));

COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;

    PRINT '=== SEED DATA FAILED — TRANSACTION ROLLED BACK ===';
    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;

-- =====================================================
-- DATA VERIFICATION
-- =====================================================

PRINT '=== DATABASE VERIFICATION ===';
PRINT '';

PRINT 'Users Count:';
SELECT COUNT(*) as [Total Users] FROM Users;

PRINT 'Organisers Count:';
SELECT COUNT(*) as [Total Organisers] FROM Organiser;

PRINT 'Participants Count:';
SELECT COUNT(*) as [Total Participants] FROM Participant;

PRINT 'Events Count:';
SELECT COUNT(*) as [Total Events] FROM Event;

PRINT 'Event Categories Count:';
SELECT COUNT(*) as [Total Categories] FROM EventCategory;

PRINT 'Enrolments Count:';
SELECT COUNT(*) as [Total Enrolments] FROM Enrolment;

PRINT 'Results Count:';
SELECT COUNT(*) as [Total Results] FROM Result;

PRINT '';
PRINT '=== SAMPLE DATA VIEW ===';
PRINT '';

PRINT 'All Users:';
SELECT UserID, Email, CONCAT(FirstName, ' ', LastName) as [Name], UserRole FROM Users;

PRINT '';
PRINT 'Enrolment Summary (with Results):';
SELECT 
    u.FirstName,
    u.LastName,
    e.EventName,
    ec.CategoryName,
    en.Status,
    r.TimeCompleted,
    r.PlacementRank
FROM Enrolment en
JOIN Participant p ON en.ParticipantID = p.ParticipantID
JOIN Users u ON p.UserID = u.UserID
JOIN EventCategory ec ON en.CategoryID = ec.CategoryID
JOIN Event e ON ec.EventID = e.EventID
LEFT JOIN Result r ON r.EnrolmentID = en.EnrolmentID;

PRINT '';
PRINT '=== VERIFICATION COMPLETE ===';
PRINT 'All tables created successfully with proper constraints and indexes.';