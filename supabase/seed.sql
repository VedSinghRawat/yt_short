-- Create a function to seed initial videos
    -- Insert sample videos
    INSERT INTO videos (title, description, id)
    VALUES
        (
            'Flutter Animation Tutorial',
            'Learn how to create smooth animations in Flutter',
            'HiUGSawr5gU'
        ),
        (
            'State Management in Flutter',
            'Understanding different state management approaches',
            'fyXCkB_KMCk'
        ),
        (
            'Flutter Navigation 2.0',
            'Deep dive into Flutter''s new navigation system',
            'US-y0W87Dr4'
        ),
        (
            'Flutter UI Best Practices',
            'Tips and tricks for building better Flutter UIs',
            's6H6aIWFTyM'
        ),
        (
            'Flutter App Architecture',
            'Learn clean architecture principles in Flutter',
            'GBtE2qCTo7w'
        )
    ON CONFLICT DO NOTHING;
-- Execute the seed function
