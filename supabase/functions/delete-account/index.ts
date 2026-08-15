import "@supabase/functions-js/edge-runtime.d.ts";
import { withSupabase } from "@supabase/server";

type Database = {
  public: {
    Tables: Record<string, never>;
    Views: Record<string, never>;
    Functions: {
      delete_user_data: {
        Args: { p_user_id: string };
        Returns: undefined;
      };
    };
    Enums: Record<string, never>;
    CompositeTypes: Record<string, never>;
  };
};

export default {
  fetch: withSupabase<Database>({ auth: "user" }, async (req, ctx) => {
    if (req.method !== "DELETE") {
      return Response.json(
        { deleted: false, message: "Method not allowed" },
        { status: 405, headers: { Allow: "DELETE" } },
      );
    }

    const userId = ctx.userClaims?.id;

    if (!userId) {
      return Response.json(
        { deleted: false, message: "Unauthorized" },
        { status: 401 },
      );
    }

    try {
      // Supabase Auth refuses to delete users that still own Storage objects.
      const { error: avatarError } = await ctx.supabaseAdmin.storage
        .from("avatars")
        .remove([`${userId}/avatar.jpg`]);

      if (avatarError) {
        throw avatarError;
      }

      // This RPC is service-role-only and is safe to retry after a partial failure.
      const { error: dataError } = await ctx.supabaseAdmin.rpc(
        "delete_user_data",
        { p_user_id: userId },
      );

      if (dataError) {
        throw dataError;
      }

      const { error: authError } = await ctx.supabaseAdmin.auth.admin
        .deleteUser(userId);

      if (authError) {
        throw authError;
      }

      return Response.json({ deleted: true });
    } catch (error) {
      console.error("Account deletion failed", error);

      return Response.json(
        {
          deleted: false,
          message: "Account deletion could not be completed. Please try again.",
        },
        { status: 500 },
      );
    }
  }),
};
