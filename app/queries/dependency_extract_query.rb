class DependencyExtractQuery < ApplicationQuery
  def initialize(endpoint, packages)
    @endpoint = endpoint
    @packages = packages
  end

  def call
    return [] if @packages.size == 0
    columns = Dependency.column_names
    sql =
      <<-SQL
        WITH RECURSIVE dependency_tree (#{columns.join(", ")}, level)
        AS (
          SELECT
            #{columns.join(", ")}, 0
          FROM dependencies
          WHERE id IN (
            SELECT
              dependencies.id
            FROM dependencies, packages, settings
            WHERE settings.endpoint_id = '#{@endpoint.id}'
            AND settings.package_id::text IN ('#{@packages.join(", ")}')
            AND settings.package_id = dependencies.package_id
            AND packages.id = dependencies.package_id
            AND packages.blocked_at IS NULL
          )

          UNION ALL

          SELECT
            #{columns.map { |col| "dependencies." + col }.join(", ")}, level + 1
          FROM dependencies, dependency_tree, packages
          WHERE dependencies.package_id = dependency_tree.dependent_package_id
          AND packages.id = dependencies.dependent_package_id
          AND dependencies.is_optional = FALSE
          AND packages.blocked_at IS NULL
        )
        SELECT * FROM dependency_tree
      SQL

    dependencies = Dependency.find_by_sql(sql.chomp)
    ActiveRecord::Associations::Preloader.new.preload dependencies, [
                                                        { package: :user },
                                                        { dependent_package: :user },
                                                        { package: :sources },
                                                        { dependent_package: :sources },
                                                      ]
    dependencies || []
  end
end