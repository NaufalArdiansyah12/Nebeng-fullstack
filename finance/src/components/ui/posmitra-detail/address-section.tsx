interface AddressSectionProps {
  address: string | null;
}

export const AddressSection = ({ address }: AddressSectionProps) => {
  return (
    <section className="mb-6">
      <h4 className="font-semibold mb-3">Alamat Terminal</h4>
      <textarea
        disabled
        className="w-full h-28 rounded-md border border-input bg-muted p-3 text-sm resize-none"
        value={address || "-"}
      />
    </section>
  );
};
