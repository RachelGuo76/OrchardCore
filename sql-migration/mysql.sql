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
		AND Content ->> Content 'Owner' = @NormalizedUserName

		SELECT @i = @i + 1
	END
END

UPDATE ContentItemIndex SET UserId = (SELECT Content ->> 'UserId') FROM Document WHERE Id = ContentItemIndex.DocumentId)

--SELECT * FROM [UserIndex] LEFT JOIN Document ON UserIndex.DocumentId = Document.Id

--SELECT Content ->> 'UserId' as UserId, Content ->> Content 'Owner' as Owner, * FROM Document WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'

--SELECT Content ->> 'UserId' as UserId, Content ->> Content 'Owner' as Owner, Content ->> 'ContentType' as ContentType, *
--FROM Document 
--WHERE Type = 'OrchardCore.ContentManagement.ContentItem, OrchardCore.ContentManagement.Abstractions'
--AND Content ->> 'UserId' is NULL
--AND (Content ->> 'ContentType' != 'ProductInformationRequest' 
--AND Content ->> 'ContentType' != 'MagazineSubscription'
--AND Content ->> 'ContentType' != 'ContactRequest')

--SELECT DISTINCT Content ->> Content 'Owner' as Owner
--FROM Document 
--WHERE Content ->> 'UserId' is NULL
--AND (Content ->> 'ContentType' != 'ProductInformationRequest' 
--AND Content ->> 'ContentType' != 'MagazineSubscription'
--AND Content ->> 'ContentType' != 'ContactRequest')

--SELECT * FROM Document WHERE Content LIKE '%souellette@centrekubota.com%'