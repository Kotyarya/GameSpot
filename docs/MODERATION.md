# GameSpot moderation runbook

This document is the owner-operated moderation process for GameSpot 1.0. It is
intentionally manual because GameSpot is a portfolio application with a small
expected user base.

Support contact: `gamespot.support@icloud.com`

## Response target

- Check the support inbox and pending reports at least once every 48 hours while
  the production app is available.
- Review urgent threats, targeted harassment, or illegal content as soon as
  possible.
- Never copy production access tokens, database passwords, or service-role keys
  into tickets, source control, screenshots, or chat.

## Review pending reports

Open the production project in Supabase Dashboard and use Table Editor for
`public.user_reports`. Filter `status = pending` and sort `created_at` ascending.

Each report stores a snapshot of the reported username and avatar URL so the
original context remains available if the user later changes their profile.
Compare repeated reports against the same `reported_user_id`, but do not treat
report count alone as proof of abuse.

Review the report reason and optional details, then choose one result:

- `dismissed`: no violation or insufficient information;
- `reviewed`: reviewed and no immediate account action is required;
- `actioned`: corrective action was taken.

Only a trusted project owner or server-side moderation tool may update report
status. The database refreshes `updated_at` automatically. The iOS client cannot
change moderation status.

## Take action

For an offensive username or avatar, contact the user through their account
email when appropriate and request a change. For severe or repeated abuse,
disable the account from Supabase Dashboard under Authentication → Users. If
permanent deletion is necessary, first verify the exact Auth user ID matches the
report's `reported_user_id`, then follow the account-deletion procedure.

After the action is complete, set the report status to `actioned`. Use
`reviewed` or `dismissed` when no account action was taken. Do not change or
delete the reporter's submission text.

## Support requests

When a user emails the support address:

1. Ask only for information needed to identify the account or incident.
2. Do not ask for a password, access token, or payment information.
3. Confirm that the report was received without disclosing another user's
   private account information or the exact enforcement action.
4. Record the decision in `user_reports.status` when a matching in-app report
   exists.

## Blocking behavior

Blocking is private to the blocker. The blocked person is not notified. The
blocker can manage the list from Profile → Blocked Users. Support should not
reveal who blocked whom.

## App Review evidence

For App Review, demonstrate this journey with two test accounts:

1. Open a game and select another player under Players.
2. Open Report User, select a reason, and submit.
3. Return to the same profile, choose Block User, and confirm the player is
   removed from the game's social sections.
4. Open Profile → Blocked Users and unblock the player.
5. Confirm the player appears again after refreshing the game.

The reviewer support contact is `gamespot.support@icloud.com`.
