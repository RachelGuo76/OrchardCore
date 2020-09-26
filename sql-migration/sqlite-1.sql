-- Assign Users with a UserId

DECLARE @count int
DECLARE @i int = 1
DECLARE @Migrate bit = 1
DECLARE @DocumentId int
DECLARE @NormalizedUserName nvarchar(255)
DECLARE @UserId nvarchar(26)

IF(@Migrate = 1)
BEGIN
	SET @count = (SELECT COUNT(*) FROM UserIndex)
	SET @i = 1
	WHILE(@i <= @count)
	BEGIN
		WITH OrderedContentItem AS
		(
			SELECT DocumentId, NormalizedUserName,
			ROW_NUMBER() OVER (ORDER BY Id) AS 'RowNumber'
			FROM UserIndex
		)
		SELECT @DocumentId = DocumentId, @NormalizedUserName = NormalizedUserName FROM OrderedContentItem WHERE RowNumber = @i
		SET @UserId = LEFT(LOWER(REPLACE(NEWID(), '-', '')), 26)

		UPDATE UserIndex SET UserId = @UserId WHERE DocumentId = @DocumentId

		-- We update Users in the Document table
		UPDATE Document
		SET Content = json_set(Content, '$.UserId', @UserId)
		WHERE Id = @DocumentId

		-- We add UserId on all ContentItems in Document table
		UPDATE Document
		SET Content = json_set(Content, '$.UserId', @UserId)
		WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'
		AND json_extract(Content, '$.Owner') = @NormalizedUserName

		SELECT @i = @i + 1
	END
END

UPDATE ContentItemIndex SET UserId = (SELECT json_extract(Content, '$.UserId') FROM Document WHERE Id = ContentItemIndex.DocumentId)

--SELECT * FROM [UserIndex] LEFT JOIN Document ON UserIndex.DocumentId = Document.Id

--SELECT json_extract(Content, '$.UserId') as UserId,json_extract(Content, '$.Owner') as Owner, * FROM Document WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'

--SELECT json_extract(Content, '$.UserId') as UserId, json_extract(Content, '$.Owner') as Owner, json_extract(Content, '$.ContentType') as ContentType, *
--FROM Document 
--WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'
--AND json_extract(Content, '$.UserId') is NULL
--AND (json_extract(Content, '$.ContentType') != 'ProductInformationRequest' 
--AND json_extract(Content, '$.ContentType') != 'MagazineSubscription'
--AND json_extract(Content, '$.ContentType') != 'ContactRequest')

--SELECT DISTINCT json_extract(Content, '$.Owner') as Owner
--FROM Document 
--WHERE json_extract(Content, '$.UserId') is NULL
--AND (json_extract(Content, '$.ContentType') != 'ProductInformationRequest' 
--AND json_extract(Content, '$.ContentType') != 'MagazineSubscription'
--AND json_extract(Content, '$.ContentType') != 'ContactRequest')

--SELECT * FROM Document WHERE Content LIKE '%souellette@centrekubota.com%'