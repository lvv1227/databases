DROP TABLE IF EXISTS PaperReviewing;
DROP TABLE IF EXISTS Reviewer;
DROP TABLE IF EXISTS Paper;
DROP TABLE IF EXISTS ConferenceEvent;
DROP TABLE IF EXISTS Conference;

CREATE TABLE Conference(
  id SERIAL PRIMARY KEY, name TEXT UNIQUE);

CREATE TABLE ConferenceEvent(
  id SERIAL PRIMARY KEY,
	conference_id INT REFERENCES Conference,
	year INT,
	UNIQUE(conference_id, year));

CREATE TABLE Paper(
  id SERIAL PRIMARY KEY,
  event_id INT REFERENCES ConferenceEvent,
  title TEXT,
  accepted BOOLEAN
);

CREATE TABLE Reviewer(
  id SERIAL PRIMARY KEY,
  email TEXT UNIQUE,
  name TEXT
);

CREATE TABLE PaperReviewing(
  paper_id INT REFERENCES Paper,
  reviewer_id INT REFERENCES Reviewer,
  score INT,
  UNIQUE(paper_id, reviewer_id)
);

INSERT INTO Conference(name) VALUES ('SIGMOD'), ('VLDB');
INSERT INTO ConferenceEvent(conference_id, year) VALUES (1, 2015), (1, 2016), (2, 2016);
INSERT INTO Reviewer(email, name) VALUES
    ('jennifer@stanford.edu', 'Jennifer Widom'),
    ('donald@ethz.ch', 'Donald Kossmann'),
    ('jeffrey@stanford.edu', 'Jeffrey Ullman'),
    ('jeff@google.com', 'Jeffrey Dean'),
    ('michael@mit.edu', 'Michael Stonebraker');

INSERT INTO Paper(event_id, title) VALUES
    (1, 'Paper1'),
    (2, 'Paper2'),
    (2, 'Paper3'),
    (3, 'Paper4');

INSERT INTO PaperReviewing(paper_id, reviewer_id) VALUES
    (1, 1), (1, 4), (1, 5),
    (2, 1), (2, 2), (2, 4),
    (3, 3), (3, 4), (3, 5),
    (4, 2), (4, 3), (4, 4);

CREATE OR REPLACE FUNCTION SubmitReview(_paper_id INT, _reviewer_id INT, _score INT)
RETURNS VOID AS $$
DECLARE
	c INT;
	av_score REAL;
BEGIN
	IF _score<1 OR _score>7 THEN
		RAISE EXCEPTION 'Score out of range';
	END IF;
	
	SELECT COUNT(*) INTO c FROM PaperReviewing
	WHERE paper_id=_paper_id AND reviewer_id=_reviewer_id;
	
	IF c=0 THEN
		INSERT INTO PaperReviewing(paper_id,reviewer_id,score)
		VALUES(_paper_id,_reviewer_id,_score);
	ELSE
		UPDATE PaperReviewing SET score=_score
		WHERE paper_id=_paper_id AND reviewer_id=_reviewer_id;
	END IF;
	
	SELECT COUNT(*) INTO c
	WHERE paper_id=_paper_id;
	
	IF c>=3 THEN
		SELECT AVG (score) into av_score FROM PaperReviewing
		WHERE paper_id=_paper_id GROUP BY score;
		
		IF score>4 THEN
			UPDATE Paper SET accepted=TRUE
			WHERE id=_paper_id;
		ELSE
			UPDATE Paper SET accepted=FALSE
			WHERE id=_paper_id;
		END IF;
	END IF;
			
		

END;
$$ LANGUAGE plpgsql;
