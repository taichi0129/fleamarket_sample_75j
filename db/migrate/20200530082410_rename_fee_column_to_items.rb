class RenameFeeColumnToItems < ActiveRecord::Migration[5.2]
  def change
    rename_column :items, :fee, :fee_id
  end
end
