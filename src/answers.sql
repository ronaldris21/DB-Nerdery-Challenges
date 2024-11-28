-- Your answers here:
-- 1
--
SELECT type account_type,
    ROUND(SUM(mount)::numeric, 2) money_sum
FROM accounts
GROUP BY type;
--
--
--
--
-- 2
--
SELECT COUNT(*) AS count_user_at_least_2_current_account
FROM (
        SELECT u.id
        FROM users u
            INNER JOIN accounts a ON u.id = a.user_id
        WHERE a.type = 'CURRENT_ACCOUNT'
        GROUP BY u.id
        HAVING COUNT(u.id) > 1
    );
--
--
--
--
--
-- 3
--
SELECT id,
    account_id,
    type,
    mount
FROM accounts
ORDER BY mount DESC
LIMIT 5;
--
--
--
--
-- 4
-- I MAKE SURE I USE EVERY ACCOUNT BY UNION ALL!
-- INNER JOIN MAY LEAVE OUT USERS WITH NO MOVEMENTS
CREATE OR REPLACE FUNCTION get_accounts_final_balance() RETURNS TABLE(account_id UUID, money NUMERIC(15, 2)) AS $$ BEGIN RETURN QUERY WITH accounts_money_movements AS (
        (
            -- account_from transactions
            SELECT account_from AS account_id,
                CASE
                    WHEN type = 'IN' THEN mount
                    ELSE mount * -1
                END AS mount
            FROM movements
        )
        UNION ALL
        (
            -- account_to transactions
            SELECT CASE
                    WHEN type = 'TRANSFER' THEN account_to
                    ELSE account_from
                END AS account_id,
                CASE
                    WHEN type = 'TRANSFER' THEN mount
                    ELSE 0
                END AS mount
            FROM movements
        )
        UNION ALL
        (
            -- accounts starting money
            SELECT id AS account_id,
                mount
            FROM accounts
        )
    )
SELECT am.account_id,
    ROUND(SUM(am.mount)::NUMERIC, 2) AS money
FROM accounts_money_movements am
GROUP BY am.account_id;
END;
$$ LANGUAGE plpgsql;
--
-- Solution applying function  get_accounts_final_balance
--
SELECT u.id,
    u.name,
    SUM (ab.money) all_money
FROM get_accounts_final_balance() ab
    INNER JOIN accounts a ON ab.account_id = a.id
    INNER JOIN users u ON u.id = a.user_id
GROUP BY u.id,
    u.name
ORDER BY all_money DESC
LIMIT 3;
--
--
--
-- 5
--
DO $$
DECLARE
    account_balance_a DOUBLE PRECISION;
    account_balance_b DOUBLE PRECISION;
	
    account_id_a UUID := '3b79e403-c788-495a-a8ca-86ad7643afaf';
    account_id_b UUID := 'fd244313-36e5-4a17-a27c-f8265bc46590';
BEGIN

	--a. First, get the ammount for the account `3b79e403-c788-495a-a8ca-86ad7643afaf` and `fd244313-36e5-4a17-a27c-f8265bc46590` after all their movements.
	
	SELECT money into account_balance_a
	FROM get_accounts_final_balance() 
	WHERE account_id = account_id_a;

	SELECT money into account_balance_b
	FROM get_accounts_final_balance() 
	WHERE account_id = account_id_b;

	RAISE NOTICE 'Account balance from % is %', account_id_a, account_balance_a;
	RAISE NOTICE 'Account balance from % is %', account_id_b, account_balance_b;

	--b. Add a new movement with the information: from: 3b79e403-c788-495a-a8ca-86ad7643afaf make a transfer to fd244313-36e5-4a17-a27c-f8265bc46590 mount: 50.75
	IF account_balance_a < 50.75 THEN
		RAISE EXCEPTION 'Account balance is insufficient!';
	ELSE 
		INSERT INTO movements  (id, type, account_from, account_to, mount) 
		VALUES (gen_random_uuid(), 'TRANSFER', account_id_a,account_id_b, 50.75);
		RAISE NOTICE 'Transfer % USD from % to % MADE SUCCESSFULLY!', 50.75, account_id_a, account_id_b;
	END IF;

	--c. Add a new movement with the information: from: 3b79e403-c788-495a-a8ca-86ad7643afaf type: OUT mount: 731823.56

	SELECT money into account_balance_a
	FROM get_accounts_final_balance() 
	WHERE account_id = account_id_a;
	
	IF account_balance_a < 731823.56 THEN
		RAISE EXCEPTION 'Account balance is insufficient!';
	ELSE 
		INSERT INTO movements  (id, type, account_from, account_to, mount) 
		VALUES (gen_random_uuid(), 'OUT', account_id_a,account_id_b );
		RAISE NOTICE 'Movement OUT % USD from % MADE SUCCESSFULLY!', 731823.56, account_id_a;
	END IF;

	--f. Once the transaction is correct, make a commit

	COMMIT;

	SELECT money into account_balance_b
	FROM get_accounts_final_balance() 
	WHERE account_id = account_id_b;

	RAISE NOTICE 'Account balance from % is %', account_id_b, account_balance_b;

EXCEPTION
--e. If the transaction fails, make the correction on step c to avoid the failure:


    WHEN OTHERS THEN
        RAISE NOTICE 'Transfer failed. Error: %', SQLERRM;
		ROLLBACK;
END;
$$;
--
--
--
--
--6. All the movements and the user information with the account 3b79e403-c788-495a-a8ca-86ad7643afaf
--
SELECT * 
FROM users u INNER JOIN accounts a ON u.id = a.user_id 
INNER JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
WHERE a.id = '3b79e403-c788-495a-a8ca-86ad7643afaf';
--
--
--
--
-- 7. The name and email of the user with the highest money in all his/her accounts
--
SELECT u.name, u.email, SUM(ab.money) money_balance FROM get_accounts_final_balance() ab
INNER JOIN accounts a ON a.id = ab.account_id 
INNER JOIN users u ON u.id = a.user_id
GROUP BY u.name, u.email
ORDER BY money_balance DESC
LIMIT 1;
--
--
--
--
-- 8. Show all the movements for the user Kaden.Gusikowski@gmail.com order by account type and created_at on the movements table
--
SELECT u.email, a.id as account_id, a.type account_type, m.id movement_id, m.type movement_type, m.account_from, m.account_to, m.mount, m.created_at 
FROM users u
INNER JOIN accounts a ON u.id = a.user_id
INNER JOIN movements m ON m.account_from = a.id OR m.account_to = a.id
WHERE u.email = 'Kaden.Gusikowski@gmail.com'
ORDER BY a.type, m.created_at



