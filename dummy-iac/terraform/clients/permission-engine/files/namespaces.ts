import { Namespace, SubjectSet, Context } from "@ory/keto-namespace-types"

class User implements Namespace {
  related: {
    manager: User[]
  }
}

class Credit implements Namespace {
  related: {
    owner: User[]
    viewer: User[]
    editor: User[]
  }

  permits = {
    view: (ctx: Context): boolean =>
      this.related.viewer.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.owner.traverse((owner) =>
        owner.related.manager.includes(ctx.subject)
      ),

    edit: (ctx: Context): boolean =>
      this.related.editor.includes(ctx.subject) ||
      this.related.owner.includes(ctx.subject) ||
      this.related.owner.traverse((owner) =>
        owner.related.manager.includes(ctx.subject)
      ),
  }
}

class Company implements Namespace {
  related: {
    member: User[]
    developer: User[]
    team_lead: User[]
    admin: User[]
  }

  permits = {
    read_code: (ctx: Context): boolean =>
      this.related.developer.includes(ctx.subject) ||
      this.related.team_lead.includes(ctx.subject) ||
      this.related.admin.includes(ctx.subject),
    
    merge_pr: (ctx: Context): boolean =>
      this.related.team_lead.includes(ctx.subject) ||
      this.related.admin.includes(ctx.subject),
    
    deploy_staging: (ctx: Context): boolean =>
      this.related.team_lead.includes(ctx.subject) ||
      this.related.admin.includes(ctx.subject),

    read_all: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject),

    write_all: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject),

    delete_users: (ctx: Context): boolean =>
      this.related.admin.includes(ctx.subject),
  }
}

// ... (tu código existente de User, Credit, Company) ...

class Services implements Namespace {
  related: {
    access: User[]
  }
}