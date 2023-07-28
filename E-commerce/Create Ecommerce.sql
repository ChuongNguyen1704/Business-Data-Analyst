-- Create the Calendar table with a timestamp column

CREATE TABLE Calendar (
    CalendarDate DATE PRIMARY KEY,
    [Year] INT,
    [Month] INT,
    [Day] INT,
    [DayOfWeek] NVARCHAR(10),
    [Week] INT,
    [Timestamp] DATETIME
);

-- Insert all dates between '2016-01-01' and '2019-12-31' into the Calendar table with the current timestamp
DECLARE @StartDate DATE = '2016-01-01';
DECLARE @EndDate DATE = '2019-12-31';

WHILE @StartDate <= @EndDate
BEGIN
    INSERT INTO Calendar (CalendarDate, [Year], [Month], [Day], [DayOfWeek], [Week], [Timestamp])
    VALUES (
        @StartDate,
        DATEPART(YEAR, @StartDate),
        DATEPART(MONTH, @StartDate),
        DATEPART(DAY, @StartDate),
        DATENAME(WEEKDAY, @StartDate),
        DATEPART(WEEK, @StartDate),
        GETDATE()  -- Use GETDATE() to get the current timestamp
    );
    
    SET @StartDate = DATEADD(DAY, 1, @StartDate);
END
